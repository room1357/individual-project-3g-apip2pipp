import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _c = PageController();
  int _index = 0;

  // Judul & deskripsi 6 layar (sesuai yang kamu pilih)
  final _titles = const [
    'Pantau Pengeluaran',
    'Anggaran Terkontrol',
    'Insight yang Jelas',
    'Kategori Fleksibel',
    'Target & Pengingat',
    'Data Aman & Ekspor',
  ];

  final _descs = const [
    'Catat setiap pengeluaran dengan cepat. SakuRapi bantu kamu tahu kemana rupiah pergi.',
    'Tetapkan batas bulanan dan pantau sisa anggaran secara real-time. Belanja lebih terarah.',
    'Grafik & ringkasan otomatis—lihat kategori paling boros dan peluang hematmu.',
    'Buat dan ubah kategori sesukamu: makan, transport, hobi, apa pun yang kamu butuhkan.',
    'Pasang target pengeluaran/tabungan; dapatkan peringatan saat mulai mendekati batas.',
    'Data disimpan di perangkatmu. Ekspor laporan kapan saja ke PDF untuk dibagikan.',
  ];

  Future<void> _goToRoute(String routeName) async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header brand: logo + nama
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icon/logo2.png', width: 32, height: 32),
                  const SizedBox(width: 12),
                  Text(
                    'SakuRapi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),

            // Halaman onboarding
            Expanded(
              child: PageView.builder(
                controller: _c,
                itemCount: _titles.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Ilustrasi besar
                        SizedBox(height: h * 0.15),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Image.asset(
                              'assets/onboarding/onboarding_${i + 1}.png',
                              height: h * 0.3,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Judul
                        Text(
                          _titles[i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Deskripsi
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _descs[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots indicator - di luar PageView agar tidak ikut geser
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_titles.length, (j) {
                  final active = j == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active 
                          ? const Color(0xFF3B82F6) 
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),

            // CTA Buttons - di luar PageView agar tidak ikut geser
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _goToRoute('/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Daftar Gratis',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _goToRoute('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer versi
                  Text(
                    'Versi 1.0',
                    style: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

