var acceptable_delay = 90;
var unkou = "http://www.tokyometro.jp/unkou/index.html";
var redo = null;
var refresh_interval = 90000;
var time_to_open_delay_inf = 600;

function init() {
	var w = window.innerWidth;
	var h = window.innerHeight;
	map = L.map('map').setView([ 35.681382, 139.766084 ], 13);
	L
			.tileLayer(
					'http://{s}.tiles.mapbox.com/v3/afterjnih.k14dcmco/{z}/{x}/{y}.png',
					// 'http://a.tiles.mapbox.com/v4/afterjnih.k14dcmco/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoiYWZ0ZXJqbmloIiwiYSI6InRQUFRDLTAifQ.kQA0HidrLU644APZLdIO2g',

					{
						attribution : 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a>, Developer <a href="https://twitter.com/koji_s_o">Koji Ota</a>',
						maxZoom : 18
					}).addTo(map);

	get_station_icons(map);

	var svg = d3.select(map.getPanes().overlayPane).append("svg").attr("width", window.innerWidth).attr("height", window.innerHeight);
	var g = svg.append("g").attr("class", "leaflet-zoom-hide");

	var colorMap = {
		20 : "#9caeb7",
		30 : "#f39700",
		40 : "#e60012",
		45 : "#e60012",
		50 : "#00a7db",
		70 : "#00ada9",
		80 : "#d7c447",
		90 : "#009944",
		110 : "#9b7cb6",
		130 : "#bb641d"
	};
	getPath(map, g, svg)
}

// パスを取得するメソッド(全路線について、上り下り両方)
function getPath(map, g, svg) {

	var jsonNameMap = {
		20 : "Hibiya",
		30 : "Ginza",
		40 : "Marunouchi",
		// 45 : "MarunouchiBranch",
		50 : "Tozai",
		70 : "Namboku",
		80 : "Yurakucho",
		90 : "Chiyoda",
		110 : "Hanzomon",
		130 : "Fukutoshin"
	};

	var colorMap = {
		20 : "#B5B5AC",
		30 : "#FF9500",
		40 : "#F62E36",
		45 : "#F62E36",
		// 46 : "#e60012",
		// 47 : "#e60012",
		50 : "#009BBF",
		70 : "#00AC9B",
		80 : "#C1A470",
		90 : "#00BB85",
		110 : "#8F76D6",
		130 : "#9C5E31"
	};

	d3.json("json/Metro.json", function(json) {

		var transform = d3.geo.transform({
			point : projectPoint
		});
		var path = d3.geo.path().projection(transform);
		var feature = g.selectAll("path").data(json.features).enter().append(
				"path").attr({
			"id" : function(d) {
				return d.id
			},
			"line_id" : function(d) {
				return d.line_id
			},
			"direction" : function(d) {
				return d.direction
			},
			"stroke" : function(d) {
				return colorMap[d.line_id];
			},
			"class" : "firstPath",
			"fill-opacity" : 1.0,
			"stroke-width" : 2
		});

		map.on("viewreset", function() {
			setPathforReset(map);
		});
		setPath();

		var pathNode = feature.node();
		var pathNodeList = [];
		feature.each(function(d, i) {
			pathNodeList.push(this);
		});
		refreshIcon(map, g, svg);
		function setPath() {
			// SVG要素をleafletのマップレイヤーにフィットさせる
			var bounds = path.bounds(json);
			var topLeft = bounds[0];
			var bottomRight = bounds[1];
			svg.attr({
				"width" : bottomRight[0] - topLeft[0],
				"height" : bottomRight[1] - topLeft[1]
			}).style({
				"left" : topLeft[0] + "px",
				"top" : topLeft[1] + "px"
			});
			g.attr("transform", "translate(" + -topLeft[0] + "," + -topLeft[1]
					+ ")");
			feature.attr("d", path).attr({
				"fill-opacity" : 0
			});
		}
		redo = setInterval(function() {
			refreshIcon(map, g, svg);
			setPath();
		}, refresh_interval);
	});
}
function refresh() {
	alert("refresh");
}
// 一分に一回列車情報を取得するメソッド
// 必要なのは路線名、向き、現在地(全体の何%か)、現在地(fromStnとtoStn:内部用)、最終地点まで何ミリ秒か,出発駅次の駅(表示用)ステータス
// 前の取得周期と同じ列車は更新しない
function refreshIcon(map, g, svg) {
	$("#loading").fadeIn();
	// var url = 'http://localhost:4567/sendjson'
		 // var url = 'http://localhost:4567/gettraininf'
		 // var url = '/gettraininf';
		 var url = '/sendjson';
	$
			.ajax({
				type : 'GET',
				// url : 'http://localhost:4567/gettraininf',
//				url : 'http://localhost:4567/traininfo.json',
				url : url,
				dataType : 'json',
				cache : false,
				success : function(train_inf, textStatus) {
					if (train_inf == "train data is empty") {
						$("#loading").fadeOut();
						alert("東京メトロ運行時間外です");
						clearInterval(redo);
					} else {
						console.info(train_inf);
						$("#header h2").text(
								"データ取得時刻/" + train_inf[0]["dc:date"]);
						var train_icons = [];
						var makerList = [];
						// IDの一致しないマーカー投入する。既存のmarkerと状態が変わらなかったらそのまま。状態が変わるマーカーだけ更新。
						train_inf
								.forEach(function(train) {
									var premadeMarker = g.select("#"
											+ train["@id"])[0][0];
									var pathNode = d3.select(
											"#" + train["direction"] + "_"
													+ train["line"]).node();

									if (premadeMarker == null) {
										var offset = 0;
										if (train["direction"] == "forward") {
											// offset = parseInt(train["offset"].slice(0, -1)) / 100;
                      offset = train["offset"];
											coordinateNum = train["coordinateNum"];
										} else {
											// offset = (100 - parseInt(train["offset"].slice(0, -1))) / 100;
                      offset = train["offset"];
											coordinateNum = train["allCoordinateNum"]
													- train["coordinateNum"];
										}
										var tmp_marker = createMarker(
												"new",
												train["@id"],
												offset,
												train["direction"],
												train["line"],
												train["odpt:fromStation"],
												train["odpt:toStation"],
												train["odpt:delay"],
												0,
												train["totalTraveltime"],
												train["fromStation4display"],
												train["toStation4display"],
												train["terminalStation4display"],
												train["railDirection4display"],
												coordinateNum, pathNode,
												pathNode.id, g, map);
										makerList.push(tmp_marker);
									} else {
										// 既存のmarkerと状態比較
										if (g.select("#" + train["@id"]).attr(
												"fromStation") != train["odpt:fromStation"]
												|| train["odpt:toStation"] != g
														.select(
																"#"
																		+ train["@id"])
														.attr("toStation")) {
											g
													.selectAll(".stnpath")
													.each(
															function() {
																if (d3
																		.select(
																				this)
																		.attr(
																				"markerUrl") == train["@id"]) {
																	d3
																			.select(
																					this)
																			.remove();
																}
															});

											g.selectAll("#" + train["@id"])
													.remove();
											var offset = 0;
											if (train["direction"] == "forward") {
												//offset = parseInt(train["offset"].slice(0, -1)) / 100;
       offset = train["offset"];
												coordinateNum = train["coordinateNum"];
											} else {
												//offset = (100 - parseInt(train["offset"].slice(0, -1))) / 100;
       offset = train["offset"];
												coordinateNum = train["allCoordinateNum"]
														- train["coordinateNum"];
											}
											var tmp_marker = createMarker(
													"renew",
													train["@id"],
													offset,
													train["direction"],
													train["line"],
													train["odpt:fromStation"],
													train["odpt:toStation"],
													train["odpt:delay"],
													0,
													train["totalTraveltime"],
													train["fromStation4display"],
													train["toStation4display"],
													train["terminalStation4display"],
													train["railDirection4display"],
													coordinateNum, pathNode,
													pathNode.id, g, map);
											makerList.push(tmp_marker);
										} else {
										}
									}
								});
						makerList
								.forEach(function(marker) {
									startTransition(
											marker[0],
											marker[1],
											Math.round(marker[0]
													.attr("totalTraveltime")) * 60 * 1000,
											g, map);
								});
						$("#loading").fadeOut();
					}
				},
				error : function(xhr, textStatus, errorThrown) {
					alert("error@refreshIcon");
					refreshIcon(map, g, svg);
				}
			});

}

// markerを作るメソッド
// markerには向き＋ラインのプロパティを作る)
function createMarker(yurai, id, offset, direction, line, fromStation,
		toStation, delay, elapsed, totalTraveltime, fromStation4display,
		toStation4display, terminalStation4display, railDirection4display,
		coordinateNum, pathNode, pathNodeId, g, map) {
	var transform = d3.geo.transform({
		point : projectPoint
	});
	var path = d3.geo.path().projection(transform);

	var paraNodeList = [];
	var paralength = 0;
	var pauseNodeNum = 0;
	var LastNodeNum = 0;
	var pausepoint = offset;
	pauseNodeNum = pathNode.getPathSegAtLength(pathNode.getTotalLength()
			* pausepoint);
	LastNodeNum = pathNode.getPathSegAtLength(pathNode.getTotalLength());

	paralength = LastNodeNum - pauseNodeNum;

	// firstPathの__data__プロパティ(①)を取得する
	var firstPathData = g.select("#" + direction + "_" + line)[0][0].__data__;

	// ①の中からcoordinatesだけ編集したいので、何個目以降の
	// coordinateを取得するか割り出す(②)。pausepointとcoordinatesのlengthを利用
	var stnCoordinatesNumber = Math
			.round(firstPathData.geometry.coordinates.length * pausepoint);

	// ①に②を適用した__data__プロパティを新規パスに組み込む
	var stnPathData = $.extend(true, {}, firstPathData);

	stnPathData.geometry.coordinates = firstPathData.geometry.coordinates
			.slice(coordinateNum);
	if (stnPathData.geometry.coordinates == 0) {
		stnPathData.geometry.coordinates = firstPathData.geometry.coordinates
				.slice(-1);
	}

	// 新規パスにfirstpathと同様の投影法をあてはめる
	var newFeature = g.append("path");
	newFeature[0][0].__data__ = stnPathData;
	newFeature.attr({
		"d" : path,
		"fill-opacity" : 0,
		"markerUrl" : id,
		"class" : "stnpath"
	});
	var newNodes = newFeature.node();
	var newPathLength = newNodes.getTotalLength();

	var tmp_circle = g
			.append("image")
			.attr("xlink:href", function(d) {
				if (delay < acceptable_delay) {
					return "sample.png"
				} else {
					return "sample_delay.png"
				}
			})
			.attr({
				width : 36,
				height : 18,
				yurai : yurai,
				id : id,
				opacity : 0.8,
				r : 10,
				fill : 'green',
				elapsed : elapsed,
				offset : offset,
				totalTraveltime : totalTraveltime,
				inode : newNodes,
				pathNodeId : pathNodeId,
				fromStation : fromStation,
				toStation : toStation,
				fromStation4display : fromStation4display,
				toStation4display : toStation4display,
				terminalStation4display : terminalStation4display,
				railDirection4display : railDirection4display,
				delay : delay,
				transform : function() {
					var p = newNodes.getPointAtLength(0);
					return "translate(" + [ p.x, p.y ] + ")";
				}
			})
			.on(
					"click",
					function() {
						var layerPoint = null;
						var from = d3.select(this).attr("fromStation4display");
						var to = d3.select(this).attr("toStation4display");
						map
								.once(
										'click',
										function(e) {
											if (delay != 0) {
												if (delay >= time_to_open_delay_inf) {
													layerPoint = e.latlng;
													popup = L
															.popup(
																	{
																		offset : L
																				.point(
																						0,
																						-5),
																		autoPan : false
																	})
															.setLatLng(
																	layerPoint)
															.setContent(
																	railDirection4display
																			+ "方面-"
																			+ terminalStation4display
																			+ "行<br>"
																			+ "出発:"
																			+ from
																			+ "駅<br>到着:"
																			+ to
																			+ "駅<br>"
																			+ "約"
																			+ Math
																					.round(delay / 60)
																			+ "分遅延<br>"
																			+ "<a href=\""
																			+ unkou
																			+ "\"target=\"_blank\">遅延情報を確認する</a>")
															.openOn(map);
												} else {
													layerPoint = e.latlng;
													popup = L
															.popup(
																	{
																		offset : L
																				.point(
																						0,
																						-5),
																		autoPan : false
																	})
															.setLatLng(
																	layerPoint)
															.setContent(
																	railDirection4display
																			+ "方面-"
																			+ terminalStation4display
																			+ "行<br>"
																			+ "出発:"
																			+ from
																			+ "駅<br>到着:"
																			+ to
																			+ "駅<br>"
																			+ "約"
																			+ Math
																					.round(delay / 60)
																			+ "分遅延")
															.openOn(map);
												}

											} else {
												layerPoint = e.latlng;
												popup = L
														.popup(
																{
																	offset : L
																			.point(
																					0,
																					-5),
																	autoPan : false
																})
														.setLatLng(layerPoint)
														.setContent(
																railDirection4display
																		+ "方面-"
																		+ terminalStation4display
																		+ "行<br>"
																		+ "出発:"
																		+ from
																		+ "駅<br>到着:"
																		+ to
																		+ "駅")
														.openOn(map);
											}
										});
					});

	var t_a = [];
	t_a.push(tmp_circle);
	t_a.push(newNodes);
	return t_a;
}

function createLineData(nodes, length, max) {
	var subPathNode = []
	for (i = 0; i <= max; i = i + 1) {
		if (length <= i) {
			var tmpNode = {};
			tmpNode.x = nodes.getItem(i).x;
			tmpNode.y = nodes.getItem(i).y;
			subPathNode.push(tmpNode);
		}
	}
	return subPathNode;
}

function startTransition(marker, pathNode, time, g, map) {
	var paraNodeList = [];
	var paralength = 0;
	var pauseNodeNum = 0;
	var LastNodeNum = 0;
	var pathLength = pathNode.getTotalLength();
	var timeTodo = time - marker.attr("elapsed");

	marker.attr("starttime", +new Date()).transition().duration(timeTodo).ease(
			"linear").attrTween("transform", translateAlong(pathNode)).each(
			"end", function() {
				d3.select(this).remove();
			});
}

function setPathforReset(map) {
	var svg = d3.select("svg");
	var g = d3.select("g");

	d3
			.json(
					"json/Metro.json",
					function(json) {
						var transform = d3.geo.transform({
							point : projectPoint
						});
						var path = d3.geo.path().projection(transform);
						var feature = g.selectAll(".firstPath");
						var pathNode = feature.node();
						var bounds = path.bounds(json);
						var topLeft = bounds[0];
						var bottomRight = bounds[1];
						svg.attr({
							"width" : bottomRight[0] - topLeft[0],
							"height" : bottomRight[1] - topLeft[1]
						}).style({
							"left" : topLeft[0] + "px",
							"top" : topLeft[1] + "px"
						});
						g.attr("transform", "translate(" + -topLeft[0] + ","
								+ -topLeft[1] + ")");
						// path要素（地形)更新
						feature.attr("d", path).attr({
							"fill-opacity" : 0
						});

						var stnfeature = g.selectAll(".stnpath");
						stnfeature.attr("d", path).attr({
							"fill-opacity" : 0
						});

						var c = g.selectAll("image");
						if (typeof (c[0][0]) != "undefined") {
							resumeTransition2(g);
						}

						function resumeTransition2(g) {
							d3.selectAll(".tmp_path").remove();
							d3
									.selectAll("image")
									.each(
											function() {
												var circle = d3.select(this);
												var elapsed = (Math
														.round((+new Date())
																- circle
																		.attr("starttime")) + parseInt(circle
														.attr("elapsed")));
												var pausepoint = elapsed
														/ (circle
																.attr("totalTraveltime") * 60 * 1000);
												var id = circle.attr("id");
												var totalTraveltime = circle
														.attr("totalTraveltime");
												var fromStation = circle
														.attr("fromStation");
												var toStation = circle
														.attr("toStation");
												var time = circle
														.attr("totalTraveltime") * 60 * 1000;
												var timeTodo = time
														- circle
																.attr("elapsed");
												var delay = circle
														.attr("delay");
												var railDirection4display = circle
														.attr("railDirection4display");
												var terminalStation4display = circle
														.attr("terminalStation4display");

												function createLineData(nodes,
														length, max) {
													var subPathNode = []
													for (i = 0; i <= max; i = i + 1) {
														if (length <= i) {
															var tmpNode = {};
															tmpNode.x = nodes
																	.getItem(i).x;
															tmpNode.y = nodes
																	.getItem(i).y;
															subPathNode
																	.push(tmpNode);
														}
													}
													return subPathNode;
												}

												var pathNode = null;
												d3
														.selectAll(".stnpath")
														.each(
																function(d, i) {
																	if (circle
																			.attr("id") == d3
																			.select(
																					this)
																			.attr(
																					"markerUrl")) {
																		pathNode = d3
																				.select(
																						this)
																				.node();

																	}
																});
												var paraNodeList = [];
												var paralength = 0;
												var pauseNodeNum = 0;
												var LastNodeNum = 0;

												pauseNodeNum = pathNode
														.getPathSegAtLength(pathNode
																.getTotalLength()
																* pausepoint);
												LastNodeNum = pathNode
														.getPathSegAtLength(pathNode
																.getTotalLength());
												paralength = LastNodeNum
														- pauseNodeNum;
												var lineFunction = d3.svg
														.line().x(function(d) {
															return d.x;
														}).y(function(d) {
															return d.y;
														})
														.interpolate("linear");

												var newFeature = g
														.append("path")
														.attr(
																{
																	"d" : lineFunction(createLineData(
																			pathNode.pathSegList,
																			pauseNodeNum,
																			LastNodeNum)),
																	"fill-opacity" : 0,
																	"class" : "tmp_path"
																});
												var newNodes = newFeature
														.node();
												var newPathLength = newNodes
														.getTotalLength();
												circle
														.on(
																"click",
																function() {
																	var from = d3
																			.select(
																					this)
																			.attr(
																					"fromStation4display");
																	var to = d3
																			.select(
																					this)
																			.attr(
																					"toStation4display");
																	var layerPoint = null;
																	map
																			.once(
																					'click',
																					function(
																							e) {
																						if (delay != 0) {
																							if (delay >= time_to_open_delay_inf) {
																								layerPoint = e.latlng;
																								popup = L
																										.popup(
																												{
																													offset : L
																															.point(
																																	0,
																																	-5),
																													autoPan : false
																												})
																										.setLatLng(
																												layerPoint)
																										.setContent(
																												railDirection4display
																														+ "方面-"
																														+ terminalStation4display
																														+ "行<br>"
																														+ "出発:"
																														+ from
																														+ "駅<br>到着:"
																														+ to
																														+ "駅<br>"
																														+ "約"
																														+ Math
																																.round(delay / 60)
																														+ "分遅延<br>"
																														+ "<a href=\""
																														+ unkou
																														+ "\"target=\"_blank\">遅延情報を確認する</a>")
																										.openOn(
																												map);
																							} else {
																								layerPoint = e.latlng;
																								popup = L
																										.popup(
																												{
																													offset : L
																															.point(
																																	0,
																																	-5),
																													autoPan : false
																												})
																										.setLatLng(
																												layerPoint)
																										.setContent(
																												railDirection4display
																														+ "方面-"
																														+ terminalStation4display
																														+ "行<br>"
																														+ "出発:"
																														+ from
																														+ "駅<br>到着:"
																														+ to
																														+ "駅<br>"
																														+ "約"
																														+ Math
																																.round(delay / 60)
																														+ "分遅延")
																										.openOn(
																												map);
																							}

																						} else {
																							layerPoint = e.latlng;
																							popup = L
																									.popup(
																											{
																												offset : L
																														.point(
																																0,
																																-5),
																												autoPan : false
																											})
																									.setLatLng(
																											layerPoint)
																									.setContent(
																											railDirection4display
																													+ "方面-"
																													+ terminalStation4display
																													+ "行<br>"
																													+ "出発:"
																													+ from
																													+ "駅<br>到着:"
																													+ to
																													+ "駅")
																									.openOn(
																											map);
																						}

																					});
																});

												circle
														.attr("starttime",
																+new Date())
														.attr({
															"fill" : "blue",
															"r" : 10
														})
														.transition()
														.duration(timeTodo)
														.ease(

														"linear")
														.attrTween(
																"transform",
																translateAlong(newNodes))
														.each(
																"end",
																function() {
																	d3
																			.select(
																					this)
																			.remove();
																});
											});
						}
					});
}

function createPoliline(latlngs, p_color, p_opacity, p_weigth) {
	var trainicons = [];
	var polipath = L.polyline(latlngs, {
		color : p_color,
		opacity : p_opacity,
		weight : p_weigth
	});
	return polipath;
}

function drawMap(line_id, line_color, map) {
	$.ajax({
		type : 'GET',
		// url : 'http://localhost:4567/getlatlngs/' + line_id,
		url : '/getlatlngs/' + line_id,
		dataType : 'json',
		cache : false,
		success : function(latlngs, textStatus) {
			var latlng_list = [];
			latlngs.forEach(function(latlng) {
				latlng_list.push(L.latLng(latlng[0], latlng[1]));
			});
			var route_without_train = createPoliline(latlng_list, line_color,
					1.0, 2);
			route_without_train.addTo(map);
		},
		error : function(xhr, textStatus, errorThrown) {
			alert("error@drawMap");
		}
	});
}

function projectPoint(x, y) {
	var point = map.latLngToLayerPoint(new L.LatLng(y, x));
	this.stream.point(point.x, point.y);
}

function translateAlong(path) {
	var l = path.getTotalLength();
	var t0 = 0;
	return function(i) {
		return function(t) {
			var p0 = path.getPointAtLength(t0 * l);//previous point
			var p = path.getPointAtLength(t * l);////current point
			var angle = Math.atan2(p.y - p0.y, p.x - p0.x) * 180 / Math.PI;//angle for tangent
			t0 = t;
			var centerX = p.x - 18, centerY = p.y - 9;
			return "translate(" + centerX + "," + centerY + ")rotate(" + angle
					+ " 18" + " 9" + ")";
		}
	}
}

function get_station_icons(map) {
	$.ajax({
		type : 'GET',
		// url : 'http://localhost:4567/getstationicons',
		url : '/getstationicons',
		dataType : 'json',
		cache : false,
		success : function(icons_inf, textStatus) {
			icons_inf.forEach(function(icon) {
				var metroIcon = L.icon({
					iconUrl : 'station_number_icon/' + icon[2],
					iconSize : [ 20, 20 ],
					iconAnchor : [ 7.5, 10 ],
					popupAnchor : [ -3, -76 ],
					shadowSize : [ 68, 95 ],
					shadowAnchor : [ 22, 94 ]
				});
				var marker = L.marker([ icon[0], icon[1] ], {
					icon : metroIcon,
					clickable : true
				});

				marker.on('click', function(e) {
					var point = L.point(10, -5);
					L.popup({
						autoPan : false,
						offset : point
					})

					.setLatLng([ icon[0], icon[1] ]).setContent(
							icon[4] + ":" + "<a href=\"" + icon[6]
									+ "\"target=\"_blank\">" + icon[3]
									+ "駅</a>").openOn(map);

				});
				marker.addTo(map);
			});
		},
		error : function(xhr, textStatus, errorThrown) {
			alert("error@get_station_icons");
		}
	});
}
