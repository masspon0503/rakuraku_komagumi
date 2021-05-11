from .interval_evaluator import IntervalEvaluator
from .occupation_and_blank_evaluator import OccupationAndBlankEvaluator
from .seat_occupation_evaluator import SeatOccupationEvaluator
from .seat_combination_evaluator import SeatCombinationEvaluator
from .vacancy_and_double_booking_evaluator import VacancyAndDoubleBookingEvaluator

class CostEvaluator():
    def __init__(
        self,
        array_size,
        student_optimization_rules,
        teacher_optimization_rule,
        student_group_occupation,
        teacher_group_occupation,
        student_vacancy,
        teacher_vacancy,
        school_grades):
        self.__interval_evaluator = IntervalEvaluator(
            array_size=array_size,
            student_optimization_rules=student_optimization_rules,
            school_grades=school_grades)
        self.__occupation_and_blank_evaluator = OccupationAndBlankEvaluator(
            array_size=array_size,
            student_optimization_rules=student_optimization_rules,
            teacher_optimization_rule=teacher_optimization_rule,
            student_group_occupation=student_group_occupation,
            teacher_group_occupation=teacher_group_occupation,
            school_grades=school_grades)
        self.__seat_occupation_evaluator = SeatOccupationEvaluator(array_size=array_size)
        self.__seat_combination_evaluator = SeatCombinationEvaluator(
            array_size=array_size,
            single_cost=teacher_optimization_rule.single_cost,
            different_pair_cost=teacher_optimization_rule.different_pair_cost)
        self.__vacancy_and_double_booking_evaluator = VacancyAndDoubleBookingEvaluator(
            student_vacancy=student_vacancy,
            teacher_vacancy=teacher_vacancy)

    def violation_and_cost(self, tutorial_pieces):
        a = self.__interval_evaluator.violation_and_cost(tutorial_pieces)
        b = self.__occupation_and_blank_evaluator.violation_and_cost(tutorial_pieces)
        c = self.__seat_occupation_evaluator.violation_and_cost(tutorial_pieces)
        d = self.__seat_combination_evaluator.violation_and_cost(tutorial_pieces)
        e = self.__vacancy_and_double_booking_evaluator.violation_and_cost(tutorial_pieces)
        violation = sum(violation_and_cost[0] for violation_and_cost in [a, b, c, d, e])
        cost = sum(violation_and_cost[1] for violation_and_cost in [a, b, c, d, e])
        return [violation, cost]