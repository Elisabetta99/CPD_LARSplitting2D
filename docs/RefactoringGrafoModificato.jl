using Pkg
Pkg.activate(".")
Pkg.add("Vega")
Pkg.add("VegaDatasets")

using Vega
using VegaDatasets
plot = @vgplot(
    height=720,
    width=720,
    padding=5,
    marks=[
        {
            encode={
                update={
                    stroke={
                        value="#ccc"
                    },
                    path={
                        field="path"
                    }
                }
            },
            from={
                data="edges"
            },
            type="path"
        },
        {
            type="symbol",
            from={
                data="arrows"
            },
            encode={
                update={
                    shape={
                        value="triangle-up"
                    },
                    x={
                        field="x"
                    },
                    angle={
                        field="angle"
                    },
                    y={
                        field="y"
                    }
                },
                enter={
                    shape={
                        value="triangle-up"
                    },
                    fill={
                        value="#ccc"
                    },
                    size={
                        value=200
                    },
                    stroke={
                        value="#555"
                    },
                    strokeWidth={
                        value=1
                    }
                }
            }
        },
        {
            encode={
                update={
                    x={
                        field="x"
                    },
                    fill={
                        field="color"
                    },
                    y={
                        field="y"
                    }
                },
                enter={
                    stroke={
                        value="#fff"
                    },
                    size={
                        value=300
                    }
                }
            },
            from={
                data="nodes"
            },
            type="symbol"
        },
        {
            encode={
                update={
                    align={
                        signal="datum.children ? 'right' : 'left'"
                    },
                    x={
                        field="x"
                    },
                    dx={
                        value=12                    
                    },
                    y={
                        field="y"
                    },
                    dy={
                        value=-10                    
                    },
                },
                enter={
                    fontSize={
                        value=15
                    },
                    text={
                        field="name"
                    },
                    baseline={
                        value="middle"
                    }
                }
            },
            from={
                data="nodes"
            },
            type="text"
        }
    ],
    data=[
        {
            name="nodes",
            values= [
                {id= 1, name="spaceindex", x=  360, y=360, color="#99cbff"},
                {id= 2, name="boundingbox", x=  360, y=250, color="#99cbff"},
                {id= 3, name="coordintervals", x=  360, y=520, color="#99cbff"},
                {id= 4, name="boxcovering", x=  500, y=360, color="#99cbff"},
                {id= 5, name="fragmentlines", x=  200, y=320, color="#99cbff"},
                {id= 6, name="pointInPolygonClassification", x=  250, y=140, color="#ffa500"},
                {id= 7, name="setTile", x=  270, y=60, color="#ffa500"},
                {id= 8, name="crossingTest", x=  90, y=100, color="#ffa500"},
                {id= 9, name="intersection", x=  170, y=500, color="#99cbff"},
                {id= 10, name="linefragments", x= 100, y=450, color="#99cbff"},
                {id= 11, name="fraglines", x=  50, y=320, color="#99cbff"},
                {id= 12, name="congruence", x=  130, y=260, color="#99cbff"},
                {id= 13, name="input_collection", x=  510, y=100, color="#ff0"},
                {id= 14, name="removeIntersection", x=  500, y=200, color="#0000ff"},
                {id= 15, name="createIntervalTree", x=  500, y=300, color="#0000ff"},
                {id= 16, name="addIntersection", x=  500, y=500, color="#0000ff"},
                {id= 17, name="edge_code1_15", x=  250, y=200, color="#0000ff"},
               ],
            transform= [
                {
                  type= "formula",
                  expr= "atan2(datum.y, datum.x)",
                  as= "angle"
                },
                {
                  type= "formula",
                  expr= "sqrt(datum.y * datum.y + datum.x * datum.x)",
                  as= "radius"
                }
              ]
        },
        {
              name= "edges",
              values= [
                {s=1, t=2},
                {s=1, t=3},
                {s=1, t=4},
                {s=5, t=1},
                {s=6, t=7},
                {s=6, t=8},
                {s=10, t=9},
                {s=5, t=10},
                {s=5, t=12},
                {s=5, t=11},
                {s=1, t=14},
                {s=1, t=15},
                {s=1, t=16},
                {s=4, t=15},
                {s=4, t=16},
                {s=6, t=17},
                ],
              transform= [
                {
                  type= "lookup",
                  from= "nodes",
                  key= "id",
                  fields= ["s", "t"],
                  as= ["source", "target"]
                },
                {
                  type= "linkpath",
                  shape= "line"
                }
            ],
        },
        {
            name="arrows",
            values=[
                {id=1, x=360, y=265, angle=0},
                {id=2, x=485, y=360, angle=450},
                {id=3, x=362, y=503, angle=60},
                {id=4, x=159, y=490, angle=20},
                {id=5, x=111, y=435, angle=80},
                {id=6, x=144, y=272, angle=82},
                {id=7, x=185, y=320, angle=78},
                {id=8, x=348, y=358, angle=100},
                {id=9, x=105, y=100, angle=40},
                {id=10, x=269, y=77, angle=128},
                {id=11, x=500, y=315, angle=0},
                {id=12, x=502, y=482, angle=60},
                {id=13, x=487, y=305, angle=60},
                {id=14, x=489, y=486, angle=30},
                {id=15, x=490, y=210, angle=45},
                {id=0, x=252, y=182, angle=60},
            ]
        }
    ]
)

