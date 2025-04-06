// import 'package:anymex/api/Mangayomi/Eval/dart/model/m_manga.dart';
// import 'package:anymex/api/Mangayomi/Model/Source.dart';
// import 'package:anymex/api/Mangayomi/Search/get_popular.dart';
// import 'package:anymex/api/Mangayomi/Search/search.dart';
// import 'package:anymex/controllers/anilist/anilist_data.dart';
// import 'package:anymex/controllers/source/source_controller.dart';
// import 'package:anymex/utils/function.dart';
// import 'package:anymex/widgets/common/glow.dart';
// import 'package:anymex/widgets/common/reusable_carousel.dart';
// import 'package:anymex/widgets/common/search_bar.dart';
// import 'package:anymex/widgets/helper/scroll_wrapper.dart';
// import 'package:anymex/widgets/minor_widgets/custom_text.dart';
// import 'package:anymex/widgets/non_widgets/snackbar.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class NovelSearchPage extends StatefulWidget {
//   final String searchTerm;
//   final Source? source;
//   const NovelSearchPage({super.key, required this.searchTerm, this.source});

//   @override
//   State<NovelSearchPage> createState() => _NovelSearchPageState();
// }

// class _NovelSearchPageState extends State<NovelSearchPage> {
//   RxMap<Source, List<MManga>?> searchData = <Source, List<MManga>?>{}.obs;

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> fetchDataForAllSources(String searchTerm) async {
//     final sources = Get.find<SourceController>().installedNovelExtensions;
//     await Future.wait(
//       sources.map((source) async {
//         try {
//           // List<MManga>? data = (await search(
//           //         source: source, query: searchTerm, page: 1, filterList: []))
//           //     ?.list;
//           List<MManga>? data = (await getPopular(
//             source: source,
//           ));
//           searchData[source] = data;
//           searchData.refresh();
//         } catch (error) {
//           snackBar('Error fetching data for ${source.name}: $error',
//               duration: 1000);
//         }
//       }),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Glow(
//         child: Scaffold(
//       body: ScrollWrapper(children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal:  10.0),
//           child: Row(
//             children: [
//               IconButton(
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor:
//                           Theme.of(context).colorScheme.surfaceContainer),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: const Icon(Icons.arrow_back_ios_new_rounded)),
//               Expanded(
//                 child: CustomSearchBar(
//                   onSubmitted: (v) async {
//                     await fetchDataForAllSources(v);
//                   },
//                   disableIcons: true,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Obx(() {
//           return searchData.isEmpty
//               ? const Center(
//                   child: AnymexText(
//                     text: "WIP",
//                     size: 20,
//                   ),
//                 )
//               : SuperListView.builder(
//                   shrinkWrap: true,
//                   padding: const EdgeInsets.only(top: 10),
//                   itemCount: searchData.length,
//                   itemBuilder: (context, index) {
//                     final entry = searchData.entries.elementAt(index);
//                     final key = entry.key;
//                     final val = entry.value;

//                     return ReusableCarousel(
//                       data: val!,
//                       title: key.name!,
//                       variant: DataVariant.extension,
//                     );
//                   },
//                 );
//         })
//       ]),
//     ));
//   }
// }
