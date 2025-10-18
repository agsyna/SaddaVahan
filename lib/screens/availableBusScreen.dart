import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/components/IndividualBusCard.dart';
import 'package:saadibus/components/SortModal.dart';
import 'package:saadibus/providers/availableBusScreenProvider.dart';

class Availablebusscreen extends StatefulWidget {
  const Availablebusscreen({super.key});

  @override
  State<Availablebusscreen> createState() => _AvailablebusscreenState();
}

class _AvailablebusscreenState extends State<Availablebusscreen> {
  @override
  void initState() {
    super.initState();
    // Load bus data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AvailableBusScreenProvider>().loadBusData();
    });
  }

  void _showSortModal() {
    final provider = Provider.of<AvailableBusScreenProvider>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ChangeNotifierProvider.value(
        value: provider,
        child: const SortModal(),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await context.read<AvailableBusScreenProvider>().loadBusData();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AvailableBusScreenProvider>(
        context,
        listen: false,
      );
      provider.updateContext(context);
    });
    // Get screen size for responsiveness
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = size.height - padding.top - padding.bottom;

    // final length = value.availableBuses.length;

    return Consumer<AvailableBusScreenProvider>(
      builder: (context, value, child) {
        return SafeArea(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(height * 0.1),
              child: AppBar(
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: size.width * 0.03,
                    vertical: height * 0.01,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                try {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/');
                                  }
                                } catch (e) {
                                  debugPrint('Navigation error: $e');
                                  context.go('/');
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_ios_outlined,
                                  color: Colors.black45,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text(
                                  value.pickupLocation.length > 15
                                      ? "${value.pickupLocation.substring(0, 15)}..."
                                      : value.pickupLocation,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: Colors.black45,
                                    size: 10,
                                  ),
                                ),
                                Text(
                                  value.dropLocation.length > 15
                                      ? "${value.dropLocation.substring(0, 15)}..."
                                      : value.dropLocation,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _showSortModal,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.sort,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: value.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : value.availableBuses.isEmpty
                  ? ListView(
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Text(value.noBusText),
                          ),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.01,
                          ),
                          itemCount: value.availableBuses.length,
                          itemBuilder: (context, index) {
                            final bus = value.availableBuses[index];
                            return IndividualBusCard(
                              busDetail: bus,
                              arrivingInText: value.arrivingInText,
                              estimatedTimeText: value.estimatedTimeText,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
