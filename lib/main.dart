
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ...existing code...
return MaterialApp(
  title: 'Flutter Weather (Demo)',
  theme: ThemeData(
    // Seed-based color scheme for consistent theming
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    useMaterial3: true,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),

    // ✅ Use CardThemeData instead of CardTheme
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 6,
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.deepPurpleAccent,
      foregroundColor: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      prefixIconColor: Colors.deepPurple,
    ),

    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ),
  ),
  home: const HomePage(),
  debugShowCheckedModeBanner: false,
);
// ...existing code...



  }
}

// Toggle this to `false` to use OpenWeatherMap API (requires API key)
const bool useMockData = true;
const String openWeatherMapApiKey = 'PASTE_YOUR_API_KEY_HERE';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<String> _cities = [
    'New Delhi',
    'Mumbai',
    'Bengaluru',
    'Chennai',
    'Kolkata',
    'San Francisco',
    'London',
    'Tokyo'
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  Map<String, WeatherInfo> _weatherCache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _fetchAllWeather();
  }

  Future<void> _fetchAllWeather() async {
    setState(() => _loading = true);
    _animController.reset();
    for (final city in _cities) {
      try {
        final info = await WeatherService.fetchWeather(city);
        _weatherCache[city] = info;
      } catch (_) {
        // ignore errors per city so UI still loads
      }
    }
    setState(() => _loading = false);
    _animController.forward();
  }

  void _addCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    if (_cities.contains(trimmed)) return;
    setState(() {
      _cities.insert(0, trimmed);
    });
    try {
      final info = await WeatherService.fetchWeather(trimmed);
      setState(() => _weatherCache[trimmed] = info);
    } catch (e) {
      // show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not fetch weather for "$trimmed".'),
        ));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _cities.where((c) => c.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather — Cards & Animations'),
        actions: [
          IconButton(
            onPressed: _fetchAllWeather,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search or add city (press Enter to add)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _addCity,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                )
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAllWeather,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final city = filtered[index];
                        final info = _weatherCache[city];
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: WeatherCard(
                            city: city,
                            info: info,
                            onTap: () async {
                              if (info == null) return;
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DetailPage(city: city, info: info),
                              ));
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // quick demo: add a random city from a set
          final demo = ['Oslo', 'Lisbon', 'Sydney', 'Auckland', 'Berlin'];
          final pick = demo[Random().nextInt(demo.length)];
          _addCity(pick);
        },
        label: const Text('Add Demo City'),
        icon: const Icon(Icons.add_location_alt),
      ),
    );
  }
}

class WeatherCard extends StatefulWidget {
  final String city;
  final WeatherInfo? info;
  final VoidCallback? onTap;

  const WeatherCard({super.key, required this.city, this.info, this.onTap});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _elevAnim = Tween<double>(begin: 2, end: 12).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final tempText = info != null ? '${info.temperature.toStringAsFixed(1)}°C' : '--';
    final subtitle = info != null ? info.condition : 'No data';

    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        _controller.forward().then((_) => _controller.reverse());
      },
      child: AnimatedBuilder(
        animation: _elevAnim,
        builder: (context, child) {
          return Card(
            elevation: _elevAnim.value,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Hero(
                    tag: 'card_${widget.city}',
                    child: CircleAvatar(
                      radius: 30,
                      child: Text(widget.city.substring(0, 1), style: const TextStyle(fontSize: 24, color: Colors.white)),
                      backgroundColor: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.city, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(subtitle, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Text(tempText, key: ValueKey(tempText), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // remove city
                      final homeState = context.findAncestorStateOfType<_HomePageState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._cities.remove(widget.city);
                        });
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String city;
  final WeatherInfo info;

  const DetailPage({super.key, required this.city, required this.info});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(city)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(tag: 'card_$city', child: Material(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 6, child: Container(padding: const EdgeInsets.all(16), child: Row(children: [
              CircleAvatar(radius: 36, child: Text(city.substring(0,1), style: const TextStyle(fontSize: 28, color: Colors.white)), backgroundColor: Colors.indigoAccent),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(city, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(info.condition, style: const TextStyle(fontSize: 16)),
              ])
            ])))),

            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Temperature', style: sub), Text('${info.temperature.toStringAsFixed(1)} °C', style: val)]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Feels Like', style: sub), Text('${info.feelsLike.toStringAsFixed(1)} °C', style: val)]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Humidity', style: sub), Text('${info.humidity}% ', style: val)]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Wind Speed', style: sub), Text('${info.windSpeed} m/s', style: val)]),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Hourly (mock)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 12,
                itemBuilder: (context, idx) {
                  final temp = info.temperature + (idx % 3 == 0 ? 1.5 * idx : -0.8 * idx);
                  return Container(
                    width: 92,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${(DateTime.now().hour + idx) % 24}:00', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          const Icon(Icons.wb_sunny),
                          const SizedBox(height: 8),
                          Text('${temp.toStringAsFixed(1)} °C', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const sub = TextStyle(fontSize: 14, color: Colors.black54);
  static const val = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
}

// Simple model to hold fetched or mock weather data
class WeatherInfo {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;

  WeatherInfo({required this.temperature, required this.feelsLike, required this.humidity, required this.windSpeed, required this.condition});

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final main = json['main'] ?? {};
    final wind = json['wind'] ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final condition = weatherList.isNotEmpty ? weatherList[0]['main'] ?? 'Clear' : 'Clear';

    return WeatherInfo(
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      condition: condition,
    );
  }
}

class WeatherService {
  // If useMockData is true, this returns random-but-reasonable data without calling network.
  static Future<WeatherInfo> fetchWeather(String city) async {
    if (useMockData) {
      // generate deterministic-looking mock values based on hash
      final seed = city.codeUnits.fold(0, (a, b) => a + b);
      final rnd = Random(seed);
      await Future.delayed(Duration(milliseconds: 400 + rnd.nextInt(700)));
      final temp = 10 + rnd.nextDouble() * 25; // 10..35
      return WeatherInfo(
        temperature: double.parse(temp.toStringAsFixed(1)),
        feelsLike: double.parse((temp - 0.5 + rnd.nextDouble()).toStringAsFixed(1)),
        humidity: 40 + rnd.nextInt(50),
        windSpeed: double.parse((0.5 + rnd.nextDouble() * 8).toStringAsFixed(1)),
        condition: ['Clear', 'Clouds', 'Rain', 'Mist', 'Haze'][rnd.nextInt(5)],
      );
    }

    // Real fetch from OpenWeatherMap (Current Weather API: metric units)
    final query = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city,
      'appid': openWeatherMapApiKey,
      'units': 'metric',
    });

    final resp = await http.get(query).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) throw Exception('Failed to fetch weather');

    final Map<String, dynamic> data = json.decode(resp.body);
    return WeatherInfo.fromJson(data);
  }
}
