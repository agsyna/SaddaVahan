import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:saadibus/providers/availableBusScreenProvider.dart';

class SortModal extends StatelessWidget {
  const SortModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailableBusScreenProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.sortByText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildSortOption(
                context,
                provider.arrivalTimeEarliestText,
                SortType.arrivalTimeAsc,
                provider,
              ),
              _buildSortOption(
                context,
                provider.arrivalTimeLatestText,
                SortType.arrivalTimeDesc,
                provider,
              ),
              _buildSortOption(
                context,
                provider.pickupDistanceNearestText,
                SortType.pickupDistanceAsc,
                provider,
              ),
              _buildSortOption(
                context,
                provider.pickupDistanceFarthestText,
                SortType.pickupDistanceDesc,
                provider,
              ),
              _buildSortOption(
                context,
                provider.dropDistanceNearestText,
                SortType.dropDistanceAsc,
                provider,
              ),
              _buildSortOption(
                context,
                provider.dropDistanceFarthestText,
                SortType.dropDistanceDesc,
                provider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    SortType sortType,
    AvailableBusScreenProvider provider,
  ) {
    final isSelected = provider.currentSortType == sortType;
    return InkWell(
      onTap: () {
        provider.sortBuses(sortType);
        context.pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
