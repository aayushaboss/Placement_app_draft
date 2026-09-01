/// Mirrors frontend/src/mockData/mockCourses.ts `Course` + `SyllabusModule`.
class Course {
  final String id;
  final String title;
  final String category;
  final String cluster;
  final String duration;
  final int modules;
  final String image;
  final String summary;

  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.cluster,
    required this.duration,
    required this.modules,
    required this.image,
    required this.summary,
  });
}

class SyllabusModule {
  final int index;
  final String title;

  const SyllabusModule({required this.index, required this.title});
}
