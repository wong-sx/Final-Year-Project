import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int currentIndex;

  const CustomBottomNavigationBar({
    super.key,
    required this.onItemSelected,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: [
         BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 0 ? Icons.home : Icons.home_outlined,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 1 ? Icons.account_circle : Icons.account_circle_outlined,
          ),
          label: 'Account',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 2 ? Icons.visibility : Icons.visibility_outlined,
          ),
          label: 'Drowsiness',
        ),
       
        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 3 ? Icons.contacts : Icons.contacts_outlined,
          ),
          label: 'Emergency',
        ),

        BottomNavigationBarItem(
          icon: Icon(
            currentIndex == 4 ? Icons.cloud : Icons.cloud_circle_outlined,
          ),
          label: 'Weather',
        ),

      ],
      onTap: onItemSelected,
    );
  }
}
