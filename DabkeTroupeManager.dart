import 'dart:io';

// ============================================================
// ABSTRACTIONS  (ISP + DIP)
// ============================================================

/// Basic lifecycle contract every controller must satisfy  (ISP – split interface)
abstract class BasicController {
  void initState();
  void dispose();
}

/// Optional contract for controllers that need network sync  (ISP)
abstract class NetworkController {
  void handleNetworkSync();
}

/// Contract every TroupeMember must fulfil  (OCP + LSP)
abstract class TroupeMember {
  String get name;
  String get city;

  /// Each subclass describes itself differently – no if/else needed (Polymorphism)
  String get roleDescription;

  /// Returns how many performances this member is assigned to
  int performanceCount = 0;

  @override
  String toString() => '$name ($roleDescription) – from $city';
}

/// Contract every Performance type must fulfil  (OCP + LSP)
abstract class Performance {
  String get title;
  String get city;
  String get date;
  bool get isCompleted;

  final List<TroupeMember> _assignedMembers = [];
  List<TroupeMember> get assignedMembers => List.unmodifiable(_assignedMembers);

  void assignMember(TroupeMember member) {
    _assignedMembers.add(member);
    member.performanceCount++;
  }

  void markCompleted();

  /// Validation hook – each subclass enforces its own special rules (OCP)
  String? validate();
}

/// Abstraction for the notification channel  (DIP)
abstract class NotificationService {
  void send(String message);
}

/// Abstraction for report generation  (SRP – reporting is its own concern)
abstract class ReportGenerator {
  void generate(List<Performance> performances, List<TroupeMember> members);
}

// ============================================================
// CONCRETE MEMBERS  (Inheritance + Polymorphism)
// ============================================================

class CoreMember extends TroupeMember {
  @override
  final String name;
  @override
  final String city;

  final String _fixedRole; // encapsulated – changed only through a defined setter

  CoreMember({required this.name, required this.city, required String role})
      : _fixedRole = role;

  @override
  String get roleDescription => 'Core – $_fixedRole';
}

class GuestPerformer extends TroupeMember {
  @override
  final String name;
  @override
  final String city;

  // A guest's role can vary per performance – stored as a mutable field
  String currentRole;

  GuestPerformer({required this.name, required this.city, required this.currentRole});

  @override
  String get roleDescription => 'Guest – $currentRole';
}

// ============================================================
// CONCRETE PERFORMANCES  (OCP – open for extension, closed for modification)
// ============================================================

class StandardPerformance extends Performance {
  @override
  final String title;
  @override
  final String city;
  @override
  final String date;

  bool _completed = false;

  StandardPerformance({required this.title, required this.city, required this.date});

  @override
  bool get isCompleted => _completed;

  @override
  void markCompleted() => _completed = true;

  @override
  String? validate() => null; // No special conditions
}

class FormalCeremonyPerformance extends Performance {
  @override
  final String title;
  @override
  final String city;
  @override
  final String date;

  bool _completed = false;

  FormalCeremonyPerformance({required this.title, required this.city, required this.date});

  @override
  bool get isCompleted => _completed;

  @override
  void markCompleted() => _completed = true;

  /// Rule: all members must wear traditional thobe – just a reminder note here
  @override
  String? validate() {
    if (assignedMembers.isEmpty) return 'Formal Ceremony requires at least one member assigned.';
    return null; // dress-code enforced operationally; flag if no one assigned
  }
}

class YouthFestivalPerformance extends Performance {
  @override
  final String title;
  @override
  final String city;
  @override
  final String date;

  bool _completed = false;
  bool _hasYouthMentor = false;

  YouthFestivalPerformance({required this.title, required this.city, required this.date});

  @override
  bool get isCompleted => _completed;

  @override
  void markCompleted() => _completed = true;

  void setYouthMentorPresent() => _hasYouthMentor = true;

  /// Rule: at least one youth mentor must be in the lineup
  @override
  String? validate() {
    if (!_hasYouthMentor) return 'Youth Festival requires at least one youth mentor in the lineup.';
    return null;
  }
}

// ============================================================
// NOTIFICATION SERVICES  (DIP – depend on abstraction)
// ============================================================

class ConsoleNotificationService implements NotificationService {
  @override
  void send(String message) => print('[NOTIFICATION] $message');
}

// VolunteerNotifier depends on the abstraction, not the concrete SMS class (DIP fix)
class VolunteerNotifier {
  final NotificationService _service;
  VolunteerNotifier(this._service); // injected via constructor

  void notify(String message) => _service.send(message);
}

// ============================================================
// REPORT GENERATOR  (SRP – single responsibility)
// ============================================================

class ConsoleReportGenerator implements ReportGenerator {
  @override
  void generate(List<Performance> performances, List<TroupeMember> members) {
    _printUpcoming(performances);
    _printMostActive(members);
    _printUnassigned(performances);
  }

  void _printUpcoming(List<Performance> performances) {
    print('\n===== Upcoming Performances =====');
    final upcoming = performances.where((p) => !p.isCompleted).toList();
    if (upcoming.isEmpty) {
      print('  No upcoming performances.');
      return;
    }
    for (final p in upcoming) {
      print('  • ${p.title} | ${p.city} | ${p.date}');
      if (p.assignedMembers.isEmpty) {
        print('    Members: (none assigned)');
      } else {
        for (final m in p.assignedMembers) {
          print('    - $m');
        }
      }
      final warning = p.validate();
      if (warning != null) print('    ⚠ $warning');
    }
  }

  void _printMostActive(List<TroupeMember> members) {
    print('\n===== Most Active Core Members =====');
    final cores = members
        .whereType<CoreMember>()
        .toList()
      ..sort((a, b) => b.performanceCount.compareTo(a.performanceCount));
    if (cores.isEmpty) {
      print('  No core members yet.');
      return;
    }
    for (final m in cores) {
      print('  • ${m.name} – ${m.performanceCount} performance(s)');
    }
  }

  void _printUnassigned(List<Performance> performances) {
    print('\n===== Performances With No Members Assigned =====');
    final empty = performances.where((p) => p.assignedMembers.isEmpty).toList();
    if (empty.isEmpty) {
      print('  All performances have at least one member.');
    } else {
      for (final p in empty) {
        print('  • ${p.title} (${p.date})');
      }
    }
  }
}

// ============================================================
// TROUPE MANAGER  (SRP – orchestrates; does not render or report itself)
// ============================================================

class TroupeManager {
  final List<TroupeMember> _members = [];
  final List<Performance> _performances = [];
  final ReportGenerator _reporter;
  final VolunteerNotifier _notifier;

  TroupeManager({required ReportGenerator reporter, required VolunteerNotifier notifier})
      : _reporter = reporter,
        _notifier = notifier;

  // -- Members --
  void addMember(TroupeMember member) {
    _members.add(member);
    print('Member added: $member');
  }

  TroupeMember? findMember(String name) =>
      _members.cast<TroupeMember?>().firstWhere(
            (m) => m!.name.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          );

  // -- Performances --
  void addPerformance(Performance performance) {
    _performances.add(performance);
    print('Performance created: ${performance.title}');
    _notifier.notify('New performance scheduled: ${performance.title} on ${performance.date}');
  }

  Performance? findPerformance(String title) =>
      _performances.cast<Performance?>().firstWhere(
            (p) => p!.title.toLowerCase() == title.toLowerCase(),
            orElse: () => null,
          );

  void assignMemberToPerformance(String memberName, String performanceTitle) {
    final member = findMember(memberName);
    final perf = findPerformance(performanceTitle);

    if (member == null) { print('Member "$memberName" not found.'); return; }
    if (perf == null)   { print('Performance "$performanceTitle" not found.'); return; }
    if (perf.isCompleted) { print('Cannot assign to a completed performance.'); return; }

    perf.assignMember(member);
    print('${member.name} assigned to "${perf.title}".');

    // If it's a Youth Festival, ask if the new member is a youth mentor
    if (perf is YouthFestivalPerformance) {
      stdout.write('Is ${member.name} a youth mentor? (yes/no): ');
      if (stdin.readLineSync()?.trim().toLowerCase() == 'yes') {
        perf.setYouthMentorPresent();
      }
    }
  }

  void markPerformanceDone(String title) {
    final perf = findPerformance(title);
    if (perf == null) { print('Performance not found.'); return; }
    final warning = perf.validate();
    if (warning != null) { print('⚠ Cannot complete: $warning'); return; }
    perf.markCompleted();
    print('"${perf.title}" marked as completed.');
  }

  void showReports() => _reporter.generate(_performances, _members);

  List<Performance> get performances => List.unmodifiable(_performances);
  List<TroupeMember> get members => List.unmodifiable(_members);
}

// ============================================================
// MAIN – Console Interaction
// ============================================================

void main() {
  final manager = TroupeManager(
    reporter: ConsoleReportGenerator(),
    notifier: VolunteerNotifier(ConsoleNotificationService()),
  );

  print('🎭 Al-Quds Dabke Troupe Manager');
  print('================================');

  bool running = true;
  while (running) {
    print('\nChoose an action:');
    print('  1. Add Core Member');
    print('  2. Add Guest Performer');
    print('  3. Create Performance');
    print('  4. Assign Member to Performance');
    print('  5. Mark Performance as Completed');
    print('  6. View Reports');
    print('  0. Exit');
    stdout.write('> ');

    final choice = stdin.readLineSync()?.trim() ?? '';

    switch (choice) {
      case '1':
        stdout.write('Name: ');
        final name = stdin.readLineSync()!.trim();
        stdout.write('City of origin: ');
        final city = stdin.readLineSync()!.trim();
        stdout.write('Fixed role (lead dancer / musician / singer / drummer): ');
        final role = stdin.readLineSync()!.trim();
        manager.addMember(CoreMember(name: name, city: city, role: role));
        break;

      case '2':
        stdout.write('Name: ');
        final name = stdin.readLineSync()!.trim();
        stdout.write('City of origin: ');
        final city = stdin.readLineSync()!.trim();
        stdout.write('Current role for this performance: ');
        final role = stdin.readLineSync()!.trim();
        manager.addMember(GuestPerformer(name: name, city: city, currentRole: role));
        break;

      case '3':
        stdout.write('Performance title: ');
        final title = stdin.readLineSync()!.trim();
        stdout.write('City: ');
        final city = stdin.readLineSync()!.trim();
        stdout.write('Date (e.g. 2025-09-15): ');
        final date = stdin.readLineSync()!.trim();
        print('Type: 1=Standard  2=Formal Ceremony  3=Youth Festival');
        stdout.write('> ');
        final type = stdin.readLineSync()?.trim() ?? '1';
        Performance perf;
        if (type == '2') {
          perf = FormalCeremonyPerformance(title: title, city: city, date: date);
        } else if (type == '3') {
          perf = YouthFestivalPerformance(title: title, city: city, date: date);
        } else {
          perf = StandardPerformance(title: title, city: city, date: date);
        }
        manager.addPerformance(perf);
        break;

      case '4':
        stdout.write('Member name: ');
        final member = stdin.readLineSync()!.trim();
        stdout.write('Performance title: ');
        final perf = stdin.readLineSync()!.trim();
        manager.assignMemberToPerformance(member, perf);
        break;

      case '5':
        stdout.write('Performance title: ');
        final title = stdin.readLineSync()!.trim();
        manager.markPerformanceDone(title);
        break;

      case '6':
        manager.showReports();
        break;

      case '0':
        running = false;
        print('Goodbye! يلا ع الدبكة 🎶');
        break;

      default:
        print('Invalid choice. Try again.');
    }
  }
}
