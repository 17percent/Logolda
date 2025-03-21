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
      controlsPadding: const EdgeInsets.fromLTRB(30, 0, 30, 50),
      pages: [
        PageViewModel(
          title: 'Page One',
          bodyWidget: const Column(
            children: [
              Text('This is a simple intro page'),
            ],
          ),
        ),
        PageViewModel(
          title: 'Page Two',
          bodyWidget: const Text('That\'s all folks'),
        ),
      ],
    );
  }
}
