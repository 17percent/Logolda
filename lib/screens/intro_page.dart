import 'package:flutter/material.dart';
import 'package:logolda/util/colors.dart';
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
      globalBackgroundColor: AppColors.spaceCadet,
      // custom Back Button
      showBackButton: true,
      overrideBack: IconButton(
        onPressed: () {
          setState(() {
            _introKey.currentState?.previous();
          });
        },
        icon: const Icon(Icons.arrow_circle_left_outlined, size: 50),
        color: AppColors.antiFlashWhite,
      ),
      // custom Next Button
      showNextButton: true,
      overrideNext: IconButton(
        onPressed: () {
          setState(() {
            _introKey.currentState?.next();
          });
        },
        icon: const Icon(Icons.arrow_circle_right_outlined, size: 50),
        color: AppColors.antiFlashWhite,
      ),
      // custom Done Button
      showDoneButton: true,
      overrideDone: IconButton(
        onPressed: () {
          setState(() {
            Navigator.pushReplacementNamed(context, '/home');
          });
        },
        icon: const Icon(Icons.check_rounded, size: 50),
        color: AppColors.antiFlashWhite,
      ),
      dotsDecorator: DotsDecorator(
        activeColor: AppColors.antiFlashWhite,
        size: const Size(10, 10),
        activeSize: const Size(20, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      controlsPadding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
      pages: [
        // Kategóriák
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
        // Események
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Események',
              'Az <Új esemény> menüpontban tudsz új eseményeket létrehozni, ahol beállíthatod az események paramétereit!'),
          bodyWidget: _buildCustomBodyWidget(
              'A leírás megfogalmazásakor törekedj részletes emlékeztető megadására, hogy később ne felejtsd el, miért hoztad létre az eseményt!',
              'assets/tutorial_page2.png'),
        ),
        // Részletek      
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Részletek',
              'Az események részleteit a főoldalon található lenyitható dobozok segítségével tudod elérni!'),
          bodyWidget: _buildCustomBodyWidget(
              'Itt lehetőséged van az esemény módosítására, törlésére, valamint ha elkészültél az eseményben meghatározott feladatokkal, akkor a zöld gomb segítségével archiválhatod az eseményt!',
              'assets/tutorial_page3.png'),
        ),
        // Archívum      
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Archívum',
              'Az archivált eseményeket az <Archívum> menüponton éred el! Minden archivált eseményért értékes pontokat gyűjthetsz!'),
          bodyWidget: _buildCustomBodyWidget(
              'Az archivált események részletei is megtekinthetők a már korábban ismertetett módon, azonban ezeket az eseményeket már csak törölni tudod az archívumból.',
              'assets/tutorial_page4.png'),
        ),
        // Profil      
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Profil',
              'A profil oldalon megtekintheted a fiókod adatait! Itt jelenik meg a rankod és az eddig összegyűjtött pontjaid száma!'),
          bodyWidget: _buildCustomBodyWidget(
              'Továbbá, nyomon követheted a létrehozott eseményeid számát az idő távlatában!',
              'assets/tutorial_page6.png'),
        ),
        // Eredménytábla      
        PageViewModel(
          titleWidget: _buildCustomTitleWidget('Eredménytábla',
              'Az eredménytábla megmutatja, hogy a jelenlegi pontjaid alapján hol helyezkedsz el a globális rangsorban!'),
          bodyWidget: _buildCustomBodyWidget(
              'Továbbá, a globális rangsor segítségével megtekintheted a többi felhasználó által elért helyezéseket!',
              'assets/tutorial_page5.png'),
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
            textAlign: TextAlign.center
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
