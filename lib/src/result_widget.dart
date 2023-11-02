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
              margin: const EdgeInsets.only(bottom: 100),
              width: double.infinity,
              height: 50,
              color: Colors.black12,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Retry",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2,
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context, true);
                      },
                      child: const Text(
                        "Confirm",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
