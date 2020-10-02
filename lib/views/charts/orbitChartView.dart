import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:k_means_cluster/k_means_cluster.dart';
import 'package:kepler/controllers/chartsController.dart';
import 'package:kepler/database/database.dart';
import 'package:kepler/models/planetData.dart';
import 'package:kepler/widgets/header/header.dart';
import 'package:kepler/widgets/progress/loading.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class OrbitChartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChartsController>(
        init: ChartsController(),
        builder: (controller) {
          return Scaffold(
            body: ListView(
              children: [
                Header(
                  "Orbit Comparison", //TODO - LOCALIZE - ORBIT COMPARISON
                      () => Navigator.of(
                    context,
                  ).pop(
                    context,
                  ),
                ),
                OrbitBuilder(
                  future: KeplerDatabase.db.getAllPlanetsOrbits(),
                )
              ],
            ),
          );
        });
  }
}

class OrbitBuilder extends StatelessWidget {
  final Future<List<PlanetData>> future;

  OrbitBuilder({
    Key key,
    @required this.future,
  }) : super(key: key);

  getClusters(List<PlanetData> planets, int clusterCount) async {
    // Set the distance measure; this can be any function of the form
    // num f(List<num> a, List<num> b): a and b contain the coordinates
    // of two instances; f returns a numerical distance between the
    // points.
    distanceMeasure = DistanceType.squaredEuclidian;

    // Create the list of instances.
    List<Instance> instances = planets
        .map((PlanetData planet) =>
            Instance([planet.orbitalPeriod, 0], id: planet.planetName))
        .toList();

    // Randomly create the initial clusters.
    List<Cluster> clusters = initialClusters(clusterCount, instances, seed: 0);

    // // Run the algorithm. - Never Used
    // var info = kmeans(clusters: clusters, instances: instances);
    // clusters.sort(
    //   (a, b) => getMaxForCluster(
    //     a,
    //   ).compareTo(
    //     getMaxForCluster(
    //       b,
    //     ),
    //   ),
    // );
    return clusters;
  }

  num getMaxForClusterList(List<Cluster> clusterlist) => clusterlist
      .map(
        (cluster) => getMaxForCluster(cluster),
      )
      .reduce(
        max,
      );
  num getMinForClusterList(List<Cluster> clusterlist) => clusterlist
      .map(
        (cluster) => getMinForCluster(cluster),
      )
      .reduce(
        min,
      );
  num getMaxForCluster(Cluster cluster) => cluster.instances
      .map(
        (planet) => planet.location.first,
      )
      .reduce(
        max,
      );
  num getMinForCluster(Cluster cluster) => cluster.instances
      .map(
        (planet) => planet.location.first,
      )
      .reduce(
        min,
      );
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cluster>>(
      future: this.future.then(
            (List<PlanetData> planetData) async => (planetData.length > 10)
                ? await this.getClusters(planetData, 10)
                : await this.getClusters(planetData, 1),
          ),
      builder:
          (BuildContext context, AsyncSnapshot<List<Cluster>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.waiting:
            return Center(
              child: Loading(),
            );
          default:
            return Container(
              width: Get.width,
              height: Get.height,
              child: SfCircularChart(

                legend: Legend(
                    isVisible: true,
                    iconHeight: 10,
                    width: Get.width.toString(),
                    height: (Get.height / 2).toString(),
                    iconWidth: 10,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap
                ),

                series: <CircularSeries>[
                  // Renders radial bar chart
                  DoughnutSeries<Cluster, String>(
                    innerRadius: '50%',
                    radius: '80%',
                    dataSource: snapshot.data,

                    xValueMapper: (data, _){
                      if(getMaxForCluster(data) < 365 || (getMinForCluster(data)/365).truncate()== 0){
                        return "${getMinForCluster(data).toStringAsFixed(2)} - ${getMaxForCluster(data).toStringAsFixed(2)} days: ${data.instances.length} planets";
                      }
                      else{
                       return "${(getMinForCluster(data)/365).toStringAsFixed(0)} - ${(getMaxForCluster(data)/365).toStringAsFixed(0)} years: ${data.instances.length} planets";
                      }
                    },

                    // yValueMapper: (data, _) => data.location.first,
                    yValueMapper: (data, _) => data.instances.length,
                    legendIconType: LegendIconType.circle,

                    dataLabelSettings: DataLabelSettings(isVisible: false),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
