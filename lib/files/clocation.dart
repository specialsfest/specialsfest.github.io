import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_fluid_slider/flutter_fluid_slider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'getCityFunction.dart';
import 'globalvariables.dart' as globals;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Cards.dart';
import 'package:universal_html/prefer_universal/html.dart' as html;
import 'package:responsive_builder/responsive_builder.dart';

List<dynamic> lMonday,
    lTuesday,
    lWednesday,
    lThursday,
    lFriday,
    lSaturday,
    lSunday;

List<dynamic> lMondayTemp = List(),
    lTuesdayTemp = List(),
    lWednesdayTemp = List(),
    lThursdayTemp = List(),
    lFridayTemp = List(),
    lSaturdayTemp = List(),
    lSundayTemp = List();

double screen_width;
num dAccuracy = 0;
var currentPos = [0.0, 0.0];
bool bStore = false;
bool bInitial = false;
bool isLocationEnabled = true;

List<String> _SpecialPlaces = List();

class CurrentLocation extends StatefulWidget {
  @override
  _CurrentLocation createState() => _CurrentLocation();
}

class _CurrentLocation extends State<CurrentLocation> {
  List<String> _sFoodType = ["All", "Food", "Drinks"];
  List<String> _sDistanceOrder = ["Ascending", "Descending"];
  List<String> _sDayName = List(7);
  List<String> _dateDayName = List(7);
  var now;
  bool bLocation = false;
  var displayTypeFood = 'All';
  var typeFood = 'All';
  int _distanceValue = 20;
  String sDistanceOrder = 'ASC';
  String displayDistanceOrder = "Ascending";
  String error;

  getMethod(int iDistance, String sDay, String sType, double lat, double long,
      List<dynamic> lDay, String dateDay, String sDistaceOrder) async {
    if (bStore == false) {
      String theUrl =
          'http://specials-fest.com/PHP/getData.php?days=$sDay&distance=$iDistance&latitude=$lat&longitude=$long&type=$sType&datestring=$dateDay&distanceorder=$sDistaceOrder';
      var res = await http
          .get(Uri.encodeFull(theUrl), headers: {"Accept": "application/json"});
      print(res.body);
      List<dynamic> responsBody = json.decode(res.body);

      switch (sDay) {
        case "Monday":
          {
            _SpecialPlaces.clear();
            lMonday = responsBody;
          }
          break;

        case "Tuesday":
          {
            lTuesday = responsBody;
          }
          break;

        case "Wednesday":
          {
            lWednesday = responsBody;
          }
          break;

        case "Thursday":
          {
            lThursday = responsBody;
          }
          break;

        case "Friday":
          {
            lFriday = responsBody;
          }
          break;

        case "Saturday":
          {
            lSaturday = responsBody;
          }
          break;

        case "Sunday":
          {
            lSunday = responsBody;
            bStore = true;
          }
          break;

        default:
          {
            print("Invalid choice");
          }
          break;
      }
      int iTeller = 0;
      responsBody.forEach((e) {
        if (_SpecialPlaces.length == 0) {
          _SpecialPlaces.add('All Places');
          _SpecialPlaces.add(responsBody[iTeller]['businessname']);
        } else if (!_SpecialPlaces.contains(
            responsBody[iTeller]['businessname'])) {
          _SpecialPlaces.add(responsBody[iTeller]['businessname']);
        }
        iTeller++;
      });
      return responsBody;
    } else {
      return lDay;
    }
  }

  @override
  void initState() {
    super.initState();
    now = new DateTime.now().weekday.toInt() - 1;
    int _iDayNow = now;
    for (int iTel = 0; iTel < 7; iTel++) {
      if (_iDayNow == 7) {
        _iDayNow = 0;
      }
      var formatter = DateFormat('dd LLL');
      var iFormatter = DateFormat('y-M-d');
      _dateDayName[_iDayNow] = iFormatter
          .format(DateTime.now().add(Duration(days: iTel)))
          .toString();
      _sDayName[_iDayNow] =
          formatter.format(DateTime.now().add(Duration(days: iTel))).toString();
      _iDayNow++;
    }

    // currentPos[0] = -26.71667;
    // currentPos[1] = 27.1;

    if ((currentPos[0] == 0.0) && (currentPos[0] == 0.0)) {
      initPlatformState();
    } else {
      setState(() {
        bLocation = true;
      });
    }
  }

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
        globals.globalAccuracy = dAccuracy;
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    screen_width = media.size.width;
    return DefaultTabController(
      initialIndex: now,
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: SearchSpecials());
              },
            )
          ],
          backgroundColor: Colors.indigo,
          centerTitle: true,
          title: Text(
            'Specials Fest',
            textScaleFactor: 1.0,
          ),
          bottom: TabBar(isScrollable: true, tabs: [
            Tab(
              text: 'Monday\n' + _sDayName[0],
            ),
            Tab(
              text: 'Tuesday\n' + _sDayName[1],
            ),
            Tab(
              text: 'Wednesday\n' + _sDayName[2],
            ),
            Tab(
              text: 'Thursday\n' + _sDayName[3],
            ),
            Tab(
              text: 'Friday\n' + _sDayName[4],
            ),
            Tab(
              text: 'Saturday\n' + _sDayName[5],
            ),
            Tab(
              text: 'Sunday\n' + _sDayName[6],
            ),
          ]),
        ),
        body: TabBarView(
          children: [
            ListDae('Monday', lMonday, _dateDayName[0]),
            ListDae('Tuesday', lTuesday, _dateDayName[1]),
            ListDae('Wednesday', lWednesday, _dateDayName[2]),
            ListDae('Thursday', lThursday, _dateDayName[3]),
            ListDae('Friday', lFriday, _dateDayName[4]),
            ListDae('Saturday', lSaturday, _dateDayName[5]),
            ListDae('Sunday', lSunday, _dateDayName[6])
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                  child: Image.asset('Fotos/logo.png'),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: <Color>[
                    Colors.deepOrangeAccent,
                    Colors.orange
                  ]))),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.fastfood,
                  color: Colors.red,
                ),
                title: Text('Special Type :'),
                trailing: DropdownButton<String>(
                  value: displayTypeFood,
                  items: _sFoodType.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                        value: dropDownStringItem,
                        child: Text(dropDownStringItem));
                  }).toList(),
                  onChanged: (String newValueSelected) {
                    if (this.mounted) {
                      this.setState(() {
                        bStore = false;
                        typeFood = newValueSelected;
                        displayTypeFood = newValueSelected;
                      });
                    }
                  },
                ),
              ),
              Divider(),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.filter_list,
                  color: Colors.blue,
                ),
                title: Text('Distance :'),
                trailing: DropdownButton<String>(
                  value: displayDistanceOrder,
                  items: _sDistanceOrder.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                        value: dropDownStringItem,
                        child: Text(dropDownStringItem));
                  }).toList(),
                  onChanged: (String newValueSelected) {
                    if (this.mounted) {
                      this.setState(() {
                        bStore = false;
                        if (newValueSelected == "Ascending") {
                          sDistanceOrder = 'ASC';
                        } else {
                          sDistanceOrder = 'DESC';
                        }
                        displayDistanceOrder = newValueSelected;
                      });
                    }
                  },
                ),
              ),
              Divider(),
              FluidSlider(
                value: _distanceValue.toDouble(),
                labelsTextStyle: TextStyle(fontSize: 15, color: Colors.white),
                min: 0.0,
                max: 200.0,
                valueTextStyle: TextStyle(fontSize: 15),
                onChanged: (double newValue) {
                  if (this.mounted) {
                    setState(() {
                      bStore = false;
                      _distanceValue = newValue.round();
                    });
                  }
                },
              ),
              Center(
                child: Container(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "Current filter distance : $_distanceValue km",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    )),
              ),
              Divider(),
              Center(
                child: RaisedButton(
                  onPressed: () {
                    setState(() {
                      bLocation = false;
                      isLocationEnabled = true;
                      bStore = false;
                      initPlatformState();
                    });
                  },
                  color: Colors.blueAccent,
                  child: Text(
                    'Reload Location',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget ListDae(String sDay, List<dynamic> lDay, String dateDay) {
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
                html.window.location.reload();
              },
              color: Colors.blueAccent,
              child: Text(
                'Reload Window',
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
        future: getMethod(_distanceValue, sDay, typeFood, currentPos[0],
            currentPos[1], lDay, dateDay, sDistanceOrder),
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
                  SizedBox(height: 50),
                  Text(
                    "Error fetching Data \n Please check your connection",
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 50,
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
                          setState(() {
                            html.window.location.reload();
                          });
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
                    ),
                  );
                },
              ),
              tablet: GridView.builder(
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 2),
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
                    ),
                  );
                },
              ),
              desktop: GridView.builder(
                gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 2),
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
                    ),
                  );
                },
              ),
            );
          } else {
            if (dAccuracy > 100) {
              return Center(
                  child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 25.0, right: 25.0),
                    child: Text(
                      'You have poor accuracy \n device probably does not have GPS \n Please search for town/city that you are located',
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
                      html.window.location.reload();
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
                  "Sorry no specials for this day \n Check filter distance",
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.0,
                ),
              );
            }
          }
        },
      );
    }
  }

  void SearchPlacePressed(String sPlace) {
    if (sPlace == 'All Places') {
      if (lMondayTemp.length != 0 ||
          lTuesdayTemp.length != 0 ||
          lWednesdayTemp.length != 0 ||
          lThursdayTemp.length != 0 ||
          lFridayTemp.length != 0 ||
          lSaturdayTemp.length != 0 ||
          lSundayTemp.length != 0) {
        lMonday = lMondayTemp;
        lTuesday = lTuesdayTemp;
        lWednesday = lWednesdayTemp;
        lThursday = lThursdayTemp;
        lFriday = lFridayTemp;
        lSaturday = lSaturdayTemp;
        lSunday = lSundayTemp;
      }
    } else {
      if (lMondayTemp.length != 0 ||
          lTuesdayTemp.length != 0 ||
          lWednesdayTemp.length != 0 ||
          lThursdayTemp.length != 0 ||
          lFridayTemp.length != 0 ||
          lSaturdayTemp.length != 0 ||
          lSundayTemp.length != 0) {
        lMonday = lMondayTemp;
        lTuesday = lTuesdayTemp;
        lWednesday = lWednesdayTemp;
        lThursday = lThursdayTemp;
        lFriday = lFridayTemp;
        lSaturday = lSaturdayTemp;
        lSunday = lSundayTemp;
      }
      lMondayTemp = List();
      lTuesdayTemp = List();
      lWednesdayTemp = List();
      lThursdayTemp = List();
      lFridayTemp = List();
      lSaturdayTemp = List();
      lSundayTemp = List();
      lMondayTemp.addAll(lMonday);
      lTuesdayTemp.addAll(lTuesday);
      lWednesdayTemp.addAll(lWednesday);
      lThursdayTemp.addAll(lThursday);
      lFridayTemp.addAll(lFriday);
      lSaturdayTemp.addAll(lSaturday);
      lSundayTemp.addAll(lSunday);
      lMonday.clear();
      lTuesday.clear();
      lWednesday.clear();
      lThursday.clear();
      lFriday.clear();
      lSaturday.clear();
      lSunday.clear();
      int iTeller = 0;
      lMondayTemp.forEach((e) {
        if (lMondayTemp[iTeller]['businessname'] == sPlace) {
          lMonday.add(lMondayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lTuesdayTemp.forEach((e) {
        if (lTuesdayTemp[iTeller]['businessname'] == sPlace) {
          lTuesday.add(lTuesdayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lWednesdayTemp.forEach((e) {
        if (lWednesdayTemp[iTeller]['businessname'] == sPlace) {
          lWednesday.add(lWednesdayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lThursdayTemp.forEach((e) {
        if (lThursdayTemp[iTeller]['businessname'] == sPlace) {
          lThursday.add(lThursdayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lFridayTemp.forEach((e) {
        if (lFridayTemp[iTeller]['businessname'] == sPlace) {
          lFriday.add(lFridayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lSaturdayTemp.forEach((e) {
        if (lSaturdayTemp[iTeller]['businessname'] == sPlace) {
          lSaturday.add(lSaturdayTemp[iTeller]);
        }
        iTeller++;
      });
      iTeller = 0;
      lSundayTemp.forEach((e) {
        if (lSundayTemp[iTeller]['businessname'] == sPlace) {
          lSunday.add(lSundayTemp[iTeller]);
        }
        iTeller++;
      });
    }
  }
}

class SearchSpecials extends SearchDelegate<String> {
  final recentSpecialSearch = _SpecialPlaces;

  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? recentSpecialSearch
        : _SpecialPlaces.where(
                (p) => p.startsWith(new RegExp(query, caseSensitive: false)))
            .toList();

    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        onTap: () {
          _CurrentLocation().SearchPlacePressed(suggestionList[index]);
          close(context, null);
        },
        leading: Icon(Icons.fastfood),
        title: RichText(
          text: TextSpan(
              text: suggestionList[index].substring(0, query.length),
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              children: [
                TextSpan(
                    text: suggestionList[index].substring(query.length),
                    style: TextStyle(color: Colors.grey))
              ]),
        ),
      ),
      itemCount: suggestionList.length,
    );
  }
}
