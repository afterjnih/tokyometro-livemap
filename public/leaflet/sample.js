// ベースタイルのレイヤを定義
// {z}、{x}、{y}はそれぞれズームレベル、タイルの水平方向インデックス、タイルの垂直方向インデックスのプレースホルダ。
function init() {
var tileUrl = 'タイルのURL{z}_{x}_{y}.jpg', 
    tileAttribution = 'タイルの権利帰属等',
    baseLayer = new L.TileLayer(tileUrl, {maxZoom: 18, attribution: tileAttribution });

// マップオプジェクト。引数はコンテナ要素のIDまたはコンテナ要素
var map = new L.Map('map'); 

// マップにベースタイルを追加する
map.setView(new L.LatLng(34.637728,135.40889713).addLayer(baseLayer));
}