// SPDX-License-Identifier: GPL-2.0-or-later
// Alpha 34 reference implementation for clipping equivalence tests.
static void referenceTriangle(std::vector<Vertex> polygon, const ImVec4& clip, qhandle_t image)
{
  for (int edge = 0; edge < 4 && !polygon.empty(); ++edge)
  {
    auto distance = [&](const Vertex& p) {
      return edge == 0   ? p.x - clip.x
             : edge == 1 ? clip.z - p.x
             : edge == 2 ? p.y - clip.y
                         : clip.w - p.y;
    };
    std::vector<Vertex> result;
    Vertex previous = polygon.back();
    float pd = distance(previous);
    for (auto current : polygon)
    {
      float cd = distance(current);
      if ((cd >= 0) != (pd >= 0))
        result.push_back(lerp(previous, current, pd / (pd - cd)));
      if (cd >= 0)
        result.push_back(current);
      previous = current;
      pd = cd;
    }
    polygon = std::move(result);
  }
  for (size_t i = 1; i + 1 < polygon.size(); ++i)
  {
    Vertex p[4] = {polygon[0], polygon[i], polygon[i + 1], polygon[i + 1]};
    // FTE's image shader culls the reverse winding. ImGui's antialias fringes
    // and custom draw lists can contain either winding, so normalize every
    // clipped triangle before encoding it as a degenerate quad.
    const float area = (p[1].x-p[0].x)*(p[2].y-p[0].y)
                     - (p[1].y-p[0].y)*(p[2].x-p[0].x);
    if (area < 0) std::swap(p[1], p[2]);
    p[3] = p[2];
    vec2_t xy[4], uv[4];
    vec4_t color[4];
    for (int j = 0; j < 4; ++j)
    {
      xy[j][0] = p[j].x;
      xy[j][1] = p[j].y;
      uv[j][0] = p[j].u;
      uv[j][1] = p[j].v;
      color[j][0] = p[j].r;
      color[j][1] = p[j].g;
      color[j][2] = p[j].b;
      color[j][3] = p[j].a;
    }
    draw->Image2dQuad(xy, uv, color, image);
  }
}
