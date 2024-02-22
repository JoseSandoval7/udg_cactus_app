import 'package:flutter/material.dart';
import 'package:udg_cactus_app/helpers/route_generator.dart';

import '../helpers/appcolors.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset('assets/imgs/bg.png', fit: BoxFit.cover),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                      child: ClipOval(
                    child: Container(
                      width: 180,
                      height: 180,
                      color: AppColors.MAIN_COLOR,
                      alignment: Alignment.center,
                      child: Tab(
                          icon: Image.asset('assets/imgs/splash.png'),
                          height: 100),
                    ),
                  )),
                  SizedBox(height: 50),
                  Text('Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                        child: Text('Escanear',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.MAIN_COLOR,
                            padding: EdgeInsets.all(25),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50))),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.camera);
                        }),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          splashColor: AppColors.MAIN_COLOR.withOpacity(0.2),
                          highlightColor: AppColors.MAIN_COLOR.withOpacity(0.2),
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.library);
                          },
                          child: Container(
                            padding: EdgeInsets.all(20),
                            child: Text("Biblioteca",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.MAIN_COLOR,
                                    fontWeight: FontWeight.bold)),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.transparent,
                                border: Border.all(
                                    color: AppColors.MAIN_COLOR, width: 4)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
