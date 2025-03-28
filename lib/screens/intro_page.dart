import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
import 'package:logolda/util/styles.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      key: _introKey,
      baseBtnStyle: AppStyles.customButtonStyle(AppColors.antiFlashWhite),
      globalBackgroundColor: AppColors.spaceCadet,
      // custom Back Button
      showBackButton: true,
      overrideBack: Container(
        decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
        child: IconButton(
          onPressed: () {
            setState(() {
              _introKey.currentState?.previous();
            });
          },
          icon: const Icon(Icons.arrow_circle_left_outlined, size: 50),
          color: AppColors.antiFlashWhite,
        ),
      ),
      // custom Next Button
      showNextButton: true,
      overrideNext: Container(
        decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
        child: IconButton(
          onPressed: () {
            setState(() {
              _introKey.currentState?.next();
            });
          },
          icon: const Icon(Icons.arrow_circle_right_outlined, size: 50),
          color: AppColors.antiFlashWhite,
        ),
      ),
      // custom Done Button
      showDoneButton: true,
      overrideDone: Container(
        decoration: AppStyles.customBoxDecoration(AppColors.coolGrey, 18),
        child: IconButton(
          onPressed: () {
            setState(() {
              Navigator.pushReplacementNamed(context, '/home');
            });
          },
          icon: const Icon(Icons.check_rounded, size: 50),
          color: AppColors.antiFlashWhite,
        ),
      ),
      dotsDecorator: DotsDecorator(
        activeColor: AppColors.antiFlashWhite,
        size: const Size(10, 10),
        activeSize: const Size(20, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      controlsPadding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
      pages: [
        // Page One
        PageViewModel(
          titleWidget: _buildCustomTitleWidget(
              'Kategóriák',
              'Első lépésben hozz létre új kategóriákat, amelyek segítenek majd rendszerezni a feladataidat!',
            ),
          bodyWidget: _buildCustomBodyWidget(
            'Ezt követően tudsz majd a feladataidhoz kategóriát hozzárendelni!',
            'assets/tutorial_page1.png',
          ),
        ),
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Események',
              'Az Új esemény menüpontban tudsz új eseményeket létrehozni, ahol beállíthatod az események paramétereit!'),
          bodyWidget: _buildCustomBodyWidget(
              'A leírás megadásakor törekedj részletes emlékeztető megadására, hogy később ne felejtsd el, miért hoztad létre az eseményt!',
              'assets/tutorial_page2.png'),
        ),
      ],
    );
  }

  Container _buildCustomTitleWidget(String title, String desc) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.antiFlashWhite,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.antiFlashWhite, thickness: 2),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.antiFlashWhite,
            ),
          ),
        ],
      ),
    );
  }

  Container _buildCustomBodyWidget(String desc, String imagePath) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Image.asset(imagePath, fit: BoxFit.fitWidth),
          const SizedBox(height: 30),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.antiFlashWhite,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
