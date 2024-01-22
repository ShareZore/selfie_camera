import 'dart:io';

import 'package:flutter/material.dart';

class ResultWidget extends StatelessWidget {
  const ResultWidget({
    super.key,
    required this.file,
  });

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.black,
                ),
              ),
              Image.file(
                file,
                width: double.maxFinite,
                fit: BoxFit.fitWidth,
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(bottom: 80, top: 20),
              width: double.infinity,
              color: Colors.black12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: const Text(
                        "Retry",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 3,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
