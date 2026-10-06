import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.title, super.key});
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 15),
            ],
            child,
          ]),
        ),
      );
}
