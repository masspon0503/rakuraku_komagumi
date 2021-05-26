import itertools
import numpy


class OptimizationResult():
    def __init__(self, update_optimization_result, term_object,
                 array_size, tutorial_occupation_array):
        self.__update_optimization_result = update_optimization_result
        self.__term_object = term_object
        self.__array_size = array_size
        self.__seat_indexes_list = self.__get_seat_indexes_list()
        self.__occupied_indexes_list = self.__get_occupied_indexes_list(
            tutorial_occupation_array)
        self.__term_teacher_id_array = self.__get_term_teacher_id_array()
        self.__tutorial_piece_id_array = self.__get_tutorial_piece_id_array()
        self.__seat_id_array = self.__get_seat_id_array()

    def __get_seat_indexes_list(self):
        return list(itertools.product(
            range(self.__array_size.date_count()),
            range(self.__array_size.period_count()),
            range(self.__term_object['term']['seat_count'])))

    def __get_occupied_indexes_list(self, tutorial_occupation_array):
        indexes_list = itertools.product(
            range(self.__array_size.student_count()),
            range(self.__array_size.teacher_count()),
            range(self.__array_size.tutorial_count()),
            range(self.__array_size.date_count()),
            range(self.__array_size.period_count()))
        return list(filter(
            lambda indexes: tutorial_occupation_array[
                indexes[0], indexes[1], indexes[2], indexes[3], indexes[4]] == 1,
            indexes_list))

    def __get_term_teacher_id_array(self):
        term_teacher_id_array = numpy.zeros(
            (self.__array_size.date_count(),
             self.__array_size.period_count(),
             self.__term_object['term']['seat_count']), dtype=int)
        for [_, teacher_index, _, date_index,
             period_index] in self.__occupied_indexes_list:
            term_teacher_id = self.__term_object['term_teachers'][teacher_index]['id']
            term_teacher_ids = term_teacher_id_array[date_index,
                                                     period_index, :]
            assigned_seat_count = numpy.count_nonzero(term_teacher_ids != 0)
            installed_seat_index = numpy.where(
                term_teacher_ids == term_teacher_id)[0]
            seat_index = assigned_seat_count if len(
                installed_seat_index) == 0 else installed_seat_index[0]
            term_teacher_id_array[date_index,
                                  period_index, seat_index] = term_teacher_id
        return term_teacher_id_array

    def __get_tutorial_piece_id_array(self):
        counter = numpy.zeros(
            (self.__array_size.student_count(),
             self.__array_size.tutorial_count()), dtype=int)
        tutorial_piece_id_array = numpy.zeros(
            (self.__array_size.student_count(),
             self.__array_size.teacher_count(),
             self.__array_size.tutorial_count(),
             self.__array_size.date_count(),
             self.__array_size.period_count()), dtype=int)
        for [student_index, teacher_index, tutorial_index, date_index,
             period_index] in self.__occupied_indexes_list:
            term_student_id = self.__term_object['term_students'][student_index]['id']
            term_teacher_id = self.__term_object['term_teachers'][teacher_index]['id']
            term_tutorial_id = self.__term_object['term_tutorials'][tutorial_index]['id']
            tutorial_pieces = list(filter(
                lambda tutorial_piece: tutorial_piece['term_student_id'] == term_student_id and
                tutorial_piece['term_teacher_id'] == term_teacher_id and
                tutorial_piece['term_tutorial_id'] == term_tutorial_id,
                self.__term_object['tutorial_pieces']))
            tutorial_piece_index = counter[student_index, tutorial_index]
            tutorial_piece_id_array[
                student_index, teacher_index, tutorial_index, date_index, period_index] = \
                tutorial_pieces[tutorial_piece_index]['id']
            counter[student_index, tutorial_index] += 1
        return tutorial_piece_id_array

    def __get_seat_id_array(self):
        seat_id_array = numpy.zeros(
            (self.__array_size.student_count(),
             self.__array_size.teacher_count(),
             self.__array_size.tutorial_count(),
             self.__array_size.date_count(),
             self.__array_size.period_count()), dtype=int)
        for [student_index, teacher_index, tutorial_index, date_index,
             period_index] in self.__occupied_indexes_list:
            term_teacher_id = self.__term_object['term_teachers'][teacher_index]['id']
            seat_index = numpy.where(
                self.__term_teacher_id_array[date_index, period_index, :] == term_teacher_id)[0][0]
            seat = next(filter(
                lambda seat: seat['date_index'] == date_index + 1 and
                seat['period_index'] == period_index + 1 and
                seat['seat_index'] == seat_index + 1,
                self.__term_object['seats']))
            seat_id_array[
                student_index, teacher_index, tutorial_index, date_index, period_index] = seat['id']
        return seat_id_array

    def __find_tutorial_piece_id(
            self, student_index, teacher_index, tutorial_index, date_index, period_index):
        return self.__tutorial_piece_id_array[
            student_index, teacher_index, tutorial_index, date_index, period_index].item()

    def __find_seat_id_by_seat(self, date_index, period_index, seat_index):
        seat = next(
            seat for seat in self.__term_object['seats']
            if seat['date_index'] == date_index + 1 and
            seat['period_index'] == period_index + 1 and
            seat['seat_index'] == seat_index + 1)
        return seat['id']

    def __find_seat_id_by_tutorial_piece(
            self, student_index, teacher_index, tutorial_index, date_index, period_index):
        return self.__seat_id_array[
            student_index, teacher_index, tutorial_index, date_index, period_index].item() or None

    def __find_term_teacher_id(self, date_index, period_index, seat_index):
        return self.__term_teacher_id_array[
            date_index, period_index, seat_index].item() or None

    def tutorial_pieces(self):
        return [
            {
                'tutorial_piece_id': self.__find_tutorial_piece_id(
                    student_index, teacher_index, tutorial_index, date_index, period_index),
                'seat_id': self.__find_seat_id_by_tutorial_piece(
                    student_index, teacher_index, tutorial_index, date_index, period_index),
                'is_fixed': True,
            }
            for [student_index, teacher_index, tutorial_index, date_index, period_index]
            in self.__occupied_indexes_list]

    def seats(self):
        return [
            {
                'seat_id': self.__find_seat_id_by_seat(date_index, period_index, seat_index),
                'term_teacher_id': self.__find_term_teacher_id(date_index, period_index, seat_index),
            }
            for [date_index, period_index, seat_index]
            in self.__seat_indexes_list]

    def write(self):
        self.__update_optimization_result.execute({
            'tutorial_pieces': self.tutorial_pieces(),
            'seats': self.seats()})