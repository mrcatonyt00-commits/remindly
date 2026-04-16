import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final double height;
  final String title;
  final bool showTitle;

  const HeaderWidget({
    super.key,
    required this.height,
    this.title = 'Remindly',
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'remindly-header',
      flightShuttleBuilder: _flightShuttleBuilder,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFF2E7CE6),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace this Container Icon with your logo asset if needed:
                  // Image.asset('assets/logo.png', width: ..., height: ...)
                  Container(
                    width: (height / 2).clamp(56.0, 120.0),
                    height: (height / 2).clamp(56.0, 120.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.vpn_key,
                        color: Color(0xFF2E7CE6),
                        size: (height / 4).clamp(28.0, 56.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (showTitle)
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (height > 180) ? 22 : 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _flightShuttleBuilder(
      BuildContext flightContext,
      Animation<double> animation,
      HeroFlightDirection flightDirection,
      BuildContext fromHeroContext,
      BuildContext toHeroContext) {
    return DefaultTextStyle(
      style: TextStyle(),
      child: toHeroContext.widget,
    );
  }
}