import 'dart:convert';

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);
DateTime monday(DateTime d) => addDays(d, 1 - d.weekday);

class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.avatar = 0,
    required this.createdAt,
  });
  String id, name, createdAt;
  int age, avatar;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'avatar': avatar,
    'createdAt': createdAt,
  };
  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
    id: j['id'],
    name: j['name'],
    age: j['age'],
    avatar: j['avatar'] ?? 0,
    createdAt: j['createdAt'],
  );
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.time,
    required this.steps,
    this.routine = 'Tag',
    this.skill = 'alltag',
    this.stars = 1,
    this.active = true,
    this.showInPlan = true,
    List<int>? days,
    List<String>? children,
  }) : days = days ?? [1, 2, 3, 4, 5, 6, 7],
       children = children ?? [];
  String id, title, icon, time, routine, skill;
  List<String> steps, children;
  List<int> days;
  int stars;
  bool active, showInPlan;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'time': time,
    'steps': steps,
    'routine': routine,
    'skill': skill,
    'stars': stars,
    'active': active,
    'showInPlan': showInPlan,
    'days': days,
    'children': children,
  };
  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: j['id'],
    title: j['title'],
    icon: j['icon'],
    time: j['time'],
    steps: List<String>.from(j['steps']),
    routine: j['routine'],
    skill: j['skill'],
    stars: j['stars'],
    active: j['active'],
    showInPlan: j['showInPlan'] ?? true,
    days: List<int>.from(j['days']),
    children: List<String>.from(j['children']),
  );
}

class RewardItem {
  RewardItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.cost,
    this.active = true,
  });
  String id, title, icon;
  int cost;
  bool active;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'cost': cost,
    'active': active,
  };
  factory RewardItem.fromJson(Map<String, dynamic> j) => RewardItem(
    id: j['id'],
    title: j['title'],
    icon: j['icon'],
    cost: j['cost'],
    active: j['active'],
  );
}

class StarEntry {
  StarEntry({
    required this.id,
    required this.childId,
    required this.source,
    required this.sourceId,
    required this.date,
    required this.label,
    required this.amount,
    this.type = 'alltag',
    this.skill = 'alltag',
    this.assisted = false,
  });
  String id, childId, source, sourceId, date, label, type, skill;
  int amount;
  bool assisted;
  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'source': source,
    'sourceId': sourceId,
    'date': date,
    'label': label,
    'amount': amount,
    'type': type,
    'skill': skill,
    'assisted': assisted,
  };
  factory StarEntry.fromJson(Map<String, dynamic> j) => StarEntry(
    id: j['id'],
    childId: j['childId'],
    source: j['source'],
    sourceId: j['sourceId'],
    date: j['date'],
    label: j['label'],
    amount: j['amount'],
    type: j['type'],
    skill: j['skill'] ?? j['type'],
    assisted: j['assisted'] ?? false,
  );
}

class Feeling {
  Feeling({required this.childId, required this.date, required this.value});
  String childId, date, value;
  Map<String, dynamic> toJson() => {
    'childId': childId,
    'date': date,
    'value': value,
  };
  factory Feeling.fromJson(Map<String, dynamic> j) =>
      Feeling(childId: j['childId'], date: j['date'], value: j['value']);
}

class WishRequest {
  WishRequest({
    required this.id,
    required this.childId,
    required this.rewardId,
    required this.title,
    required this.cost,
    required this.date,
    this.status = 'offen',
  });
  String id, childId, rewardId, title, date, status;
  int cost;
  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'rewardId': rewardId,
    'title': title,
    'cost': cost,
    'date': date,
    'status': status,
  };
  factory WishRequest.fromJson(Map<String, dynamic> j) => WishRequest(
    id: j['id'],
    childId: j['childId'],
    rewardId: j['rewardId'],
    title: j['title'],
    cost: j['cost'],
    date: j['date'],
    status: j['status'],
  );
}

class PlanItem {
  PlanItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.time,
    this.active = true,
  });
  String id, title, icon, time;
  bool active;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'time': time,
    'active': active,
  };
  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
    id: j['id'],
    title: j['title'],
    icon: j['icon'],
    time: j['time'],
    active: j['active'],
  );
}

class AppData {
  AppData();
  List<ChildProfile> children = [];
  List<TaskItem> tasks = [];
  List<RewardItem> rewards = [];
  List<StarEntry> stars = [];
  List<Feeling> feelings = [];
  List<WishRequest> requests = [];
  List<PlanItem> plans = [];
  Set<String> planChecks = {};
  Map<String, List<String>> dailyPlans = {};
  String selectedId = '', pinHash = '', salt = '';
  bool motion = true, sound = true, haptics = true;
  int sequence = 0;
  String nextId(String prefix) => '$prefix${++sequence}';
  Map<String, dynamic> toJson() => {
    'schema': 2,
    'children': children.map((x) => x.toJson()).toList(),
    'tasks': tasks.map((x) => x.toJson()).toList(),
    'rewards': rewards.map((x) => x.toJson()).toList(),
    'stars': stars.map((x) => x.toJson()).toList(),
    'feelings': feelings.map((x) => x.toJson()).toList(),
    'requests': requests.map((x) => x.toJson()).toList(),
    'plans': plans.map((x) => x.toJson()).toList(),
    'planChecks': planChecks.toList(),
    'dailyPlans': dailyPlans,
    'selectedId': selectedId,
    'pinHash': pinHash,
    'salt': salt,
    'motion': motion,
    'sound': sound,
    'haptics': haptics,
    'sequence': sequence,
  };
  AppData copy() => AppData.fromJson(jsonDecode(jsonEncode(toJson())));
  factory AppData.fromJson(Map<String, dynamic> j) {
    if (j['schema'] != 2) {
      throw const FormatException(
        'Die Sicherung gehört nicht zu dieser App-Version.',
      );
    }
    final d = AppData();
    d.children = (j['children'] as List)
        .map((x) => ChildProfile.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.tasks = (j['tasks'] as List)
        .map((x) => TaskItem.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.rewards = (j['rewards'] as List)
        .map((x) => RewardItem.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.stars = (j['stars'] as List)
        .map((x) => StarEntry.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.feelings = (j['feelings'] as List)
        .map((x) => Feeling.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.requests = (j['requests'] as List)
        .map((x) => WishRequest.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.plans = (j['plans'] as List)
        .map((x) => PlanItem.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    d.planChecks = Set<String>.from(j['planChecks']);
    d.dailyPlans = (j['dailyPlans'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, List<String>.from(v)),
    );
    d.selectedId = j['selectedId'];
    d.pinHash = j['pinHash'];
    d.salt = j['salt'];
    d.motion = j['motion'];
    d.sound = j['sound'];
    d.haptics = j['haptics'];
    d.sequence = j['sequence'];
    return d;
  }
}
