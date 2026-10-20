void fb_document_remap(int model,int oldid,int newid);
int history_revision_serial,history_base_revision;
void fb_tool_refresh();
//history is implemented using a ringbuffer
typedef struct
{
	float timestamp;
    int revision;
    int selectionop, selectioncount;
    selbrush_t *selection;
	int brushmodel;
	int wasdelete;
	int id;
	brushface_t *brushdata;	//list of faces
	patchvert_t *patchdata;	//list of control points
	union
	{
		struct
		{
			int numfaces;
			int contents;
		} brushinfo;
		patchinfo_t patchinfo;
	};
} history_t;
history_t *historyring;
int historyring_length;
int history_min;	//oldest we can go
int history;		//updated on each change
float history_transaction;
int history_max;	//max value for redo

//when replaying history, ids get changed, which makes things fun. this updates selection state for edited brushes.
void(int modelidx, int old, int new) history_remap =
{
    fb_document_remap(modelidx,old,new);
	for (int i = history_min; i < history_max; i++)
	{
		history_t *h = &historyring[i & (historyring_length-1)];
		for (int j=0; j<h->selectioncount; j++)
            if(h->selection[j].model==modelidx && h->selection[j].id==old) h->selection[j].id=new;
        if (h->brushmodel == modelidx && h->id == old)
			h->id = new;
	}
	
	int i = brush_isselected(modelidx, old);
	if (i)
	{
		i--;
		brush_selected(modelidx, old, -1, FALSE);
		brush_selected(modelidx, new, -1, TRUE);
		selectedbrushes[i].id = new;
	}
};

void(history_t *h) history_restore_selection =
{
    brush_deselectall();
    for(int i=0;i<h->selectioncount;i++) {
        selbrush_t item=h->selection[i];
        if(brush_get(item.model,item.id,__NULL__,0,__NULL__)<=0) continue;
        brush_select(item.model,item.id);
        selectedbrushes[selectedbrushcount-1].facemask=item.facemask;
    }
};
void() brush_undo =
{
    fb_tool_refresh();
	if (history == history_min)
		print("Nothing to undo.\n");
	do
	{
		if (history <= history_min)
			return;
		history--;

		history_t *h = &historyring[history & (historyring_length-1)];

		if(h->selectionop) { history_restore_selection(h); return; }
        //we're undoing, so deletes create and creates delete. weird, yes.
		if (h->wasdelete)
		{
			int newid;
			if (h->patchdata)
				newid = patch_create(h->brushmodel, 0, h->patchdata, h->patchinfo);
			else
				newid = brush_create(h->brushmodel, h->brushdata, h->brushinfo.numfaces, h->brushinfo.contents);
			history_remap(h->brushmodel, h->id, newid);
			h->id = newid;
            brush_select(h->brushmodel, newid);
		}
		else
		{
            brush_deselect(h->brushmodel, h->id);
			brush_delete(h->brushmodel, h->id);
			// Keep the logical id so resurrection remaps only this brush.
		}
		if (history == history_min)
			break;	//as far back as we can go, more timestamps are invalid
	} while (!historyring[(history-1) & (historyring_length-1)].selectionop && historyring[(history-1) & (historyring_length-1)].timestamp == h->timestamp);
};
void() brush_redo =
{
    fb_tool_refresh();
	if (history == history_max)
		print("Nothing to redo.");
	do
	{
		if (history >= history_max)
			return;

		history_t *h = &historyring[history & (historyring_length-1)];

		if(h->selectionop) { brush_deselectall(); history++; return; }
        //we're redoing stuff that has previously been done. yay.
		if (h->wasdelete)
		{
            brush_deselect(h->brushmodel, h->id);
			brush_delete(h->brushmodel, h->id);
			// Keep the logical id so resurrection remaps only this brush.
		}
		else
		{
			int newid;
			if (h->patchdata)
				newid = patch_create(h->brushmodel, 0, h->patchdata, h->patchinfo);
			else
				newid = brush_create(h->brushmodel, h->brushdata, h->brushinfo.numfaces, h->brushinfo.contents);
			history_remap(h->brushmodel, h->id, newid);
			h->id = newid;
            brush_select(h->brushmodel, newid);
		}
		history++;
		if (history == history_max)
			return;	//don't poke beyond the end...
	} while (!historyring[history & (historyring_length-1)].selectionop && historyring[history & (historyring_length-1)].timestamp == h->timestamp);
};

history_t *() history_allocate =	//returns a new history entry.
{
	if (!historyring)
	{
		history_min = history_max = history;
		historyring_length = 512;
		historyring = memalloc(sizeof(*historyring)*historyring_length);
	}
	history_t *h = &historyring[history & (historyring_length-1)];
	
	history++;
	history_max = history;	//always break any pending redos
	if (history_min < history_max - historyring_length) {
        history_base_revision=historyring[history_min & (historyring_length-1)].revision;
        history_min = history_max - historyring_length;
    }
    h->revision=++history_revision_serial;
	
	memfree(h->selection); h->selection=__NULL__; h->selectioncount=0; h->selectionop=0;
    h->timestamp = history_transaction?history_transaction:gettime(0); // Editor gestures must not share a paused server timestamp.
	if (h->brushdata)
        for (int f=0; f<h->brushinfo.numfaces; f++) strunzone(h->brushdata[f].shadername);
    memfree(h->patchdata);
    h->patchdata = __NULL__;
	memfree(h->brushdata);
	h->brushdata = __NULL__;
	return h;
};
void(history_t *h) history_deallocate =	//cancels a newly created history entry, in case something went wrong.
{
	history--;
	if (h == &historyring[history & (historyring_length-1)])
		history_max--;
};
//create and journal.
int(int mod, brushface_t *faces, int numfaces, int contents, float selectnow) brush_history_create =
{
	history_t *h = history_allocate();

	h->brushdata = memalloc(sizeof(brushface_t) * numfaces);
	memcpy(h->brushdata, faces, sizeof(brushface_t) * numfaces);
	for (int f=0; f<numfaces; f++) h->brushdata[f].shadername = strzone(faces[f].shadername);
	h->brushinfo.numfaces = numfaces;
	h->brushinfo.contents = contents;
	h->brushmodel = mod;
	h->wasdelete = FALSE;

	h->id = brush_create(h->brushmodel, h->brushdata, h->brushinfo.numfaces, h->brushinfo.contents);

	if (!h->id)
		history_deallocate(h);
	else if (selectnow)
		brush_select(mod, h->id);
	return h->id;
};
//create and journal.
int(int mod, patchvert_t *vert, patchinfo_t info, float selectnow) patch_history_create =
{
	int totalcp = info.cpwidth * info.cpheight;
	history_t *h = history_allocate();

	h->patchdata = memalloc(sizeof(patchvert_t) * totalcp);
	memcpy(h->patchdata, vert, sizeof(patchvert_t) * totalcp);
	h->patchinfo = info;
	h->brushmodel = mod;
	h->wasdelete = FALSE;

	h->id = patch_create(h->brushmodel, 0, vert, info);

	if (!h->id)
		history_deallocate(h);
	else if (selectnow)
		brush_select(mod, h->id);
	return h->id;
};
//delete and journal.
void(int mod, int id) brush_history_delete =
{
	int numfaces = brush_get(mod, id, __NULL__, 0, __NULL__);
	int numcp = patch_getcp(mod, id, __NULL__, 0, __NULL__);
	brush_deselect(mod, id);

	if (!numfaces && !numcp)
		return;	//doesn't exist or something, some kind of error. we can't log a delete if it didn't delete anything, if only because we can't recreate it if its undone.
		
	history_t *h = history_allocate();

	h->brushmodel = mod;
	h->id = id;
	h->wasdelete = TRUE;

	if (numcp)
	{
		h->patchdata = memalloc(sizeof(patchvert_t) * numcp);
		patch_getcp(mod, id, h->patchdata, numcp, &h->patchinfo);
	}
	else
	{
		h->brushdata = memalloc(sizeof(brushface_t) * numfaces);
		h->brushinfo.numfaces = brush_get(mod, id, h->brushdata, numfaces, &h->brushinfo.contents);
        for (int f=0; f<h->brushinfo.numfaces; f++) h->brushdata[f].shadername = strzone(h->brushdata[f].shadername);
	}
	brush_delete(mod, id);
};

int(int mod, int id, brushface_t *faces, int numfaces, int contents) brush_history_edit =
{
    // The delete snapshot also calls brush_get; preserve incoming temporary strings.
    brushface_t *saved = memalloc(sizeof(brushface_t)*numfaces);
    memcpy(saved, faces, sizeof(brushface_t)*numfaces);
    for (int f=0; f<numfaces; f++) saved[f].shadername = strzone(faces[f].shadername);
	int wasselected = brush_isselected(mod, id);
	if (wasselected)
		selectedbrushes[wasselected-1].id = -id;	//hack so that brush_history_delete won't remove this entry.
	brush_history_delete(mod, id);
	id = brush_history_create(mod, saved, numfaces, contents, FALSE);
    for (int f=0; f<numfaces; f++) strunzone(saved[f].shadername);
    memfree(saved);
	if (wasselected)
	{
		selectedbrushes[wasselected-1].id = id;
		brush_selected(mod, id, -1, TRUE);
	}
	return id;
};
int(int mod, int id, patchvert_t *vert, patchinfo_t info) patch_history_edit =
{
	int wasselected = brush_isselected(mod, id);
	if (wasselected)
		selectedbrushes[wasselected-1].id = -id;	//hack so that brush_history_delete won't remove this entry.
	brush_history_delete(mod, id);
	id = patch_history_create(mod, vert, info, FALSE);
	if (wasselected)
	{
		selectedbrushes[wasselected-1].id = id;
		brush_selected(mod, id, -1, TRUE);
	}
	return id;
};

// Escape deselection is an isolated history step, independent of paused engine time.
void() brush_history_deselect =
{
    if(!selectedbrushcount) return;
    history_t *h=history_allocate();
    h->selectionop=TRUE;
    h->selectioncount=selectedbrushcount;
    h->selection=memalloc(sizeof(selbrush_t)*selectedbrushcount);
    memcpy(h->selection,selectedbrushes,sizeof(selbrush_t)*selectedbrushcount);
    brush_deselectall();
};
