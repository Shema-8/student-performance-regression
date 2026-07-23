/// Mirrors the FastAPI `StudentFeatures` Pydantic model field-for-field —
/// keep the two in sync if the model schema ever changes.
class StudentInput {
  int gender; // 0 = female, 1 = male
  String raceEthnicity; // group A..E
  String parentalEducation; // some high school .. master's degree
  int lunch; // 0 = free/reduced, 1 = standard
  int testPreparationCourse; // 0 = none, 1 = completed

  StudentInput({
    this.gender = 0,
    this.raceEthnicity = 'group B',
    this.parentalEducation = "bachelor's degree",
    this.lunch = 1,
    this.testPreparationCourse = 0,
  });

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'race_ethnicity': raceEthnicity,
        'parental_level_of_education': parentalEducation,
        'lunch': lunch,
        'test_preparation_course': testPreparationCourse,
      };
}
