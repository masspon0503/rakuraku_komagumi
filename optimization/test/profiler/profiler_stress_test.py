import copy
import line_profiler
import logging
import sys
from src.array_builder.array_builder import ArrayBuilder
from src.cost_evaluator.cost_evaluator import CostEvaluator
from src.tutorial_piece_evaluator.tutorial_piece_evaluator import TutorialPieceEvaluator
from src.installer.installer import Installer
from src.swapper.swapper import Swapper
from src.deletion.deletion import Deletion
from src.installer import installer
from src.swapper import swapper
from src.deletion import deletion
from src.cost_evaluator import cost_evaluator
from test.test_data.generate_stress_test_data import generate_stress_test_data


PROCESS_COUNT = 4


def stress_test_swapper():
    stress_test_term_data = generate_stress_test_data()
    term_object = copy.deepcopy(stress_test_term_data)
    array_builder = ArrayBuilder(term_object=term_object)
    cost_evaluator = CostEvaluator(
        array_size=array_builder.array_size(),
        student_optimization_rules=term_object['student_optimization_rules'],
        teacher_optimization_rule=term_object['teacher_optimization_rules'][0],
        student_group_occupation=array_builder.student_group_occupation_array(),
        teacher_group_occupation=array_builder.teacher_group_occupation_array(),
        student_vacancy=array_builder.student_vacancy_array(),
        teacher_vacancy=array_builder.teacher_vacancy_array(),
        school_grades=array_builder.school_grade_array())
    tutorial_piece_evaluator = TutorialPieceEvaluator(
        array_size=array_builder.array_size(),
        student_optimization_rules=term_object['student_optimization_rules'],
        teacher_optimization_rule=term_object['teacher_optimization_rules'][0],
        student_group_occupation=array_builder.student_group_occupation_array(),
        teacher_group_occupation=array_builder.teacher_group_occupation_array(),
        student_vacancy=array_builder.student_vacancy_array(),
        teacher_vacancy=array_builder.teacher_vacancy_array(),
        school_grades=array_builder.school_grade_array())
    installer = Installer(
        process_count=PROCESS_COUNT,
        term_object=term_object,
        array_size=array_builder.array_size(),
        tutorial_piece_count_array=array_builder.tutorial_piece_count_array(),
        timetable_array=array_builder.timetable_array(),
        tutorial_occupation_array=array_builder.tutorial_occupation_array(),
        cost_evaluator=cost_evaluator,
        optimization_log=None)
    installer.execute()
    swapper = Swapper(
        process_count=PROCESS_COUNT,
        term_object=term_object,
        array_size=array_builder.array_size(),
        timetable_array=array_builder.timetable_array(),
        tutorial_occupation_array=array_builder.tutorial_occupation_array(),
        fixed_tutorial_occupation_array=array_builder.fixed_tutorial_occupation_array(),
        tutorial_piece_count_array=array_builder.tutorial_piece_count_array(),
        cost_evaluator=cost_evaluator,
        tutorial_piece_evaluator=tutorial_piece_evaluator,
        optimization_log=None)
    swapper.execute()
    deletion = Deletion(
        term_object=term_object,
        tutorial_occupation_array=array_builder.tutorial_occupation_array(),
        fixed_tutorial_occupation_array=array_builder.fixed_tutorial_occupation_array(),
        tutorial_piece_count_array=array_builder.tutorial_piece_count_array(),
        cost_evaluator=cost_evaluator,
        tutorial_piece_evaluator=tutorial_piece_evaluator,
        optimization_log=None)
    deletion.execute()


format = "%(asctime)s %(levelname)s %(name)s :%(message)s"
logging.basicConfig(level='INFO', filename='log/test.log', format=format)
sys.path.append('./src')

profiler = line_profiler.LineProfiler()
profiler.add_module(installer)
profiler.add_module(swapper)
profiler.add_module(deletion)
profiler.runcall(stress_test_swapper)
with open('log/profiler_stress_test.log', 'w') as file:
    profiler.print_stats(stream=file)