import 'dart:math';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
//import 'restuarants.dart';
import 'getCityFunction.dart';
import 'Cards.dart';
import 'globalvariables.dart' as globals;
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/prefer_universal/html.dart' as html;
import 'package:responsive_builder/responsive_builder.dart';

double screen_width;
bool isLocationEnabled = true;
bool _permission = false;
var currentPos = [0.0, 0.0];
bool bInitial = false;
bool bStore = false;
num dAccuracy = 0;

class StatMonitor extends StatefulWidget {
  final String sEmail;
  final String sBusinessName;
  final String sPhoneNumber;
  final String sUserID;
  final String sSpecialCount;
  final String iValidUntil;
  final String iLimit;

  const StatMonitor(
      {Key key,
      this.sEmail,
      this.sBusinessName,
      this.sPhoneNumber,
      this.sUserID,
      this.sSpecialCount,
      this.iValidUntil,
      this.iLimit})
      : super(key: key);

  @override
  _StatMonitor createState() => _StatMonitor();
}

class _StatMonitor extends State<StatMonitor> {
  List colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.blueAccent,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.redAccent,
    Colors.greenAccent
  ];

  String iSpecialCount;

  Location _locationService = new Location();
  bool isLocationEnabled = true;
  bool bLocation = false;
  String error;

  @override
  void initState() {
    super.initState();
    refreshCount();

    if (globals.globalAccuracy < 100)
    {
      currentPos[0] = globals.globalPosition[0];
      currentPos[1] = globals.globalPosition[1];
      dAccuracy = globals.globalAccuracy;
    }

    if ((currentPos[0] == 0.0) && (currentPos[0] == 0.0)) {
      initPlatformState();
    } else {
      setState(() {
        bLocation = true;
      });
    }
  }

  Future<Null> pullRefresh() async {
    setState(() {
      bStore = false;
    });
    await Future.delayed(Duration(seconds: 2));
    return null;
  }

  // Get user location
  initPlatformState() async {
    bool locEnabled = false;
    html.window.navigator.geolocation
        .getCurrentPosition(
            enableHighAccuracy: true,
            timeout: Duration(seconds: 5),
            maximumAge: Duration(seconds: 0))
        .then((e) {
      locEnabled = true;
      setState(() {
        dAccuracy = e.coords.accuracy;
        currentPos[0] = e.coords.latitude;
        currentPos[1] = e.coords.longitude;
        globals.globalPosition[0] = e.coords.latitude;
        globals.globalPosition[1] = e.coords.longitude;
        bLocation = true;

        if (!bInitial && dAccuracy < 100) {
          getCityofUser(e.coords.latitude, e.coords.longitude);
          bInitial = true;
        }
      });
    }).whenComplete(() {
      if (!locEnabled) {
        setState(() {
          isLocationEnabled = false;
        });
      }
    });
  }

  getMethod(String sConfig) async {
    var result =
        await http.post("http://specials-fest.com/PHP/getStatData.php", body: {
      "config": sConfig,
      "sdateday": DateFormat("yyyy-MM-dd").format(DateTime.now()).toString(),
    });
    List<dynamic> responsBody = json.decode(result.body);
    return responsBody;
  }

  getMethodSpecials() async {
    var result = await http
        .post("http://specials-fest.com/PHP/getUserSpecials.php", body: {
      "useremail": widget.sEmail,
      "dCurrentLat": globals.globalPosition[0].toString(),
      "dCurrentLong": globals.globalPosition[1].toString(),
    });
    List<dynamic> responsBody = json.decode(result.body);
    return responsBody;
  }

  @override
  Widget build(BuildContext context) {
    //Dynamically create
    // TODO: implement build
    final media = MediaQuery.of(context);
    screen_width = media.size.width;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.redAccent,
          centerTitle: true,
          title: Text('Statistic Monitor'),
          bottom: TabBar(tabs: [
            Tab(
              text: 'Today',
            ),
            Tab(
              text: 'Month',
            ),
            Tab(
              text: 'My Active\n Specials',
            )
          ]),
        ),
        body: TabBarView(
          children: [
            Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: AutoSizeText(
                    'The information displayed below is the number of times the application has been accessed in each city',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: StatMonitorBuilder('Today'))
              ],
            ),
            Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: AutoSizeText(
                    'The information displayed below is the number of times the application has been accessed in each city',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(child: StatMonitorBuilder('Month'))
              ],
            ),
            /*Scaffold(
              body: ListSpecialsUser(),
              floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  //*************************************************************************************************************************************//
                  refreshCount();
                  Navigator.push(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => new Restaurants(
                              sEmail: widget.sEmail,
                              sBusinessName: widget.sBusinessName,
                              sPhoneNumber: widget.sPhoneNumber,
                              sUserID: widget.sUserID,
                              sSpecialCount: iSpecialCount,
                              iValidUntil: widget.iValidUntil,
                              iLimit: widget.iLimit)));
                },
                tooltip: 'Add new Special',
              ),
            )*/
          ],
        ),
      ),
    );
  }

  Widget StatMonitorBuilder(String sConfig) {
    return FutureBuilder(
      future: getMethod(sConfig),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        List snap = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Error fetching Data \n Please check your connection",
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: 5,
                ),
                Container(
                  child: RawMaterialButton(
                    shape: CircleBorder(),
                    fillColor: Colors.blueAccent,
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (this.mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  width: 50,
                  height: 50,
                )
              ],
            ),
          );
        }
        if (snap.length != 0) {
          return Column(
            children: <Widget>[
              ListTile(
                leading: Icon(
                  Icons.all_inclusive,
                  color: Colors.black87,
                ),
                title: Text('Total of ' + sConfig),
                trailing: Text(
                  '${snap[0]['stot']}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snap.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: <Widget>[
                        Divider(),
                        ListTile(
                          leading: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors[Random().nextInt(colors.length)],
                            ),
                            child: Center(
                                child: Text(
                              '${snap[index]['stattown'][0]}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white),
                            )),
                          ),
                          title: Text(
                            '${snap[index]['stattown']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            '${snap[index]['statcount']}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: Text(
              "Sorry no application accessed for " + sConfig,
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }

  Widget ListSpecialsUser() {
    if (!bLocation) {
      //Die load aan die begin waar sy value true is
      if (!isLocationEnabled) {
        return Center(
            child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 25.0, right: 25.0),
              child: Text(
                'Please ENABLE your location to display specials',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Open Sans',
                    fontSize: 20),
              ),
            ),
            RaisedButton(
              onPressed: () {
                initPlatformState();
              },
              color: Colors.blueAccent,
              child: Text(
                'Enable Location',
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        ));
      } else {
        return Center(
          child: Text(
            'Getting location...',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontFamily: 'Open Sans',
                fontSize: 20),
          ),
        );
      }
    } else {
      return FutureBuilder(
        future: getMethodSpecials(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          List snap = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Error fetching Data \n Please check your connection",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    child: RawMaterialButton(
                      shape: CircleBorder(),
                      fillColor: Colors.blueAccent,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (this.mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    width: 50,
                    height: 50,
                  )
                ],
              ),
            );
          }
          if (snap.length != 0) {
            return ScreenTypeLayout(
              mobile: ListView.builder(
                itemCount: snap.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: CardsDisplay(
                      sImageURL: "${snap[index]['imageurl']}",
                      sSpecialName: "${snap[index]['specialname']}",
                      sBusiness: "${snap[index]['businessname']}",
                      sDistance: "${snap[index]['distance']}",
                      sSpecialDescription:
                          "${snap[index]['specialdescription']}",
                      sPhoneNumber: '${snap[index]['phonenumber']}',
                      sLatitude: '${snap[index]['latitude']}',
                      sLongitude: '${snap[index]['longitude']}',
                      bNetworkImage: true,
                      bShowLocation: true,
                      iSize: 180,
                    ),
                  );
                },
              ),
              tablet: GridView.builder(
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 1),
                itemCount: snap.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: CardsDisplay(
                      sImageURL: "${snap[index]['imageurl']}",
                      sSpecialName: "${snap[index]['specialname']}",
                      sBusiness: "${snap[index]['businessname']}",
                      sDistance: "${snap[index]['distance']}",
                      sSpecialDescription:
                          "${snap[index]['specialdescription']}",
                      sPhoneNumber: '${snap[index]['phonenumber']}',
                      sLatitude: '${snap[index]['latitude']}',
                      sLongitude: '${snap[index]['longitude']}',
                      bNetworkImage: true,
                      bShowLocation: true,
                      iSize: 180,
                    ),
                  );
                },
              ),
              desktop: GridView.builder(
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 1.5),
                itemCount: snap.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: CardsDisplay(
                      sImageURL: "${snap[index]['imageurl']}",
                      sSpecialName: "${snap[index]['specialname']}",
                      sBusiness: "${snap[index]['businessname']}",
                      sDistance: "${snap[index]['distance']}",
                      sSpecialDescription:
                          "${snap[index]['specialdescription']}",
                      sPhoneNumber: '${snap[index]['phonenumber']}',
                      sLatitude: '${snap[index]['latitude']}',
                      sLongitude: '${snap[index]['longitude']}',
                      bNetworkImage: true,
                      bShowLocation: true,
                      iSize: 250,
                    ),
                  );
                },
              ),
            );
          } else {
            return Center(
              child: Text(
                "No Active Specials",
                textAlign: TextAlign.center,
              ),
            );
          }
        },
      );
    }
  }

  void refreshCount() async {
    final response =
        await http.post("http://specials-fest.com/PHP/refreshCount.php", body: {
      "userID": widget.sUserID,
    }).catchError((e) {
      setState(() {});
    });

    var datauser = json.decode(response.body);
    print(datauser[0]['specialcount']);
    if (datauser.length != 0) {
      setState(() {
        iSpecialCount = datauser[0]['specialcount'];
        print(iSpecialCount);
      });
    }
  }
}