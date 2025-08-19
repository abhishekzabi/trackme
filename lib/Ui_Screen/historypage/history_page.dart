
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:trackingapp/Ui_Screen/historypage/history_detailed_page.dart';
// import 'package:trackingapp/utilities/MyString.dart';
// import 'package:intl/intl.dart';

// class HistoryPage extends StatelessWidget {
//   final List<Map<String, dynamic>> history;
//   const HistoryPage({super.key, required this.history});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         centerTitle: true,
//         title: const Text(
//           "Journey History",
//           style: TextStyle(color: Colors.white, fontFamily: MyString.poppins),
//         ),
//         backgroundColor: const Color(0xff0D0D3C),
//       ),
//       body: history.isEmpty
//           ? const Center(
//               child: Text(
//                 "No journeys yet",
//                 style: TextStyle(fontFamily: MyString.poppins),
//               ),
//             )
//           : ListView.builder(
//               itemCount: history.length,
//               itemBuilder: (context, index) {
//                 final item = history[index];

//                 // ✅ Handle both Firestore Timestamp & DateTime
//                 DateTime dateTime;
//                 if (item['date'] is DateTime) {
//                   dateTime = item['date'];
//                 } else if (item['date'].toString().contains("Timestamp")) {
//                   dateTime = item['date'].toDate();
//                 } else {
//                   dateTime = DateTime.tryParse(item['date'].toString()) ??
//                       DateTime.now();
//                 }

//                 // ✅ Format with intl
//                 final formattedDate =
//                     DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

//                 return Column(
//                   children: [
//                     ListTile(
//                       leading: const Icon(Icons.directions),
//                       title: Text(
//                         "${item['start']['address']} → ${item['end']['address']}",
//                         style:
//                             const TextStyle(fontFamily: MyString.poppins),
//                       ),
//                       subtitle: Text(
//                         "Distance: ${item['distance'].toStringAsFixed(2)} km\n"
//                         "Date: $formattedDate",
//                         style: const TextStyle(fontFamily: MyString.poppins),
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => JourneyMapPage(
//                               start: LatLng(
//                                 item['start']['lat'],
//                                 item['start']['lng'],
//                               ),
//                               end: LatLng(
//                                 item['end']['lat'],
//                                 item['end']['lng'],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                     Divider(
//                       color: Colors.grey.shade400,
//                       thickness: 1,
//                       indent: 15,
//                       endIndent: 15,
//                     ),
//                   ],
//                 );
//               },
//             ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trackingapp/Ui_Screen/historypage/history_detailed_page.dart';
import 'package:trackingapp/utilities/MyString.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const HistoryPage({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Journey History",
          style: TextStyle(color: Colors.white, fontFamily: MyString.poppins),
        ),
        backgroundColor: const Color(0xff0D0D3C),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                "No journeys yet",
                style: TextStyle(fontFamily: MyString.poppins),
              ),
            )
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                // ✅ Handle both Firestore Timestamp & DateTime
                DateTime dateTime;
                if (item['date'] is DateTime) {
                  dateTime = item['date'];
                } else if (item['date'].toString().contains("Timestamp")) {
                  dateTime = item['date'].toDate();
                } else {
                  dateTime = DateTime.tryParse(item['date'].toString()) ??
                      DateTime.now();
                }

                // ✅ Format with intl
                final formattedDate =
                    DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.directions),
                      title: Text(
                        "${item['start']['address']} → ${item['end']['address']}",
                        style: const TextStyle(fontFamily: MyString.poppins),
                      ),
                      subtitle: Text(
                        "Distance: ${(item['distance'] as num).toStringAsFixed(2)} km\n"
                        "Date: $formattedDate",
                        style: const TextStyle(fontFamily: MyString.poppins),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JourneyMapPage(
                              start: LatLng(
                                (item['start']['lat'] as num).toDouble(),
                                (item['start']['lng'] as num).toDouble(),
                              ),
                              end: LatLng(
                                (item['end']['lat'] as num).toDouble(),
                                (item['end']['lng'] as num).toDouble(),
                              ),
                              route: item['route'], // 👈 Pass actual travelled path here
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: Colors.grey.shade400,
                      thickness: 1,
                      indent: 15,
                      endIndent: 15,
                    ),
                  ],
                );
              },
            ),
    );
  }
}
