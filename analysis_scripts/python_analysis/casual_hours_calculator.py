globals().clear()

import pandas as pd
import datetime
from tabulate import tabulate
import numpy as np
from pyarrow import feather
import common

output_directory = common.set_output_directory("casual_hours_calculator\\")

def my_tabulate(results):
    if isinstance(results, type(pd.Series())):
        results = pd.DataFrame(results)
    print(tabulate(results, headers='keys', tablefmt='psql'))


class WorkDay:
    date = None
    timesheet = None
    summary = None

    def __init__(self, date, timesheet, summary):
        self.date = date
        self.timesheet = timesheet
        self.summary = summary


class Summary:
    start = None
    stop = None
    total_worked = None
    total_worked_decimal = None
    total_gross = None
    total_rest = None
    start_rest = None
    stop_rest = None

    def __init__(self, start, stop, total_worked, total_worked_decimal, total_gross, total_rest, start_rest, stop_rest):
        self.start = start
        self.stop = stop
        self.total_worked = total_worked
        self.total_worked_decimal = total_worked_decimal
        self.total_gross = total_gross
        self.total_rest = total_rest
        self.start_rest = start_rest
        self.stop_rest = stop_rest


def enter_timesheet(date, episodes):

    timesheet = pd.DataFrame()
    timesheet['start'] = pd.Series(dtype='datetime64[ns]')
    timesheet['stop'] = pd.Series(dtype='datetime64[ns]')
    timesheet['hours'] = pd.Series(dtype='timedelta64[ns]')

    for episode in episodes:

        marker_list = []

        for marker in episode:
            marker_list.append(
                pd.Timestamp(date.year, date.month, date.day,
                int(marker.split(':')[0]), int(marker.split(':')[1])))

        hours = \
            pd.Timestamp(date.year, date.month, date.day, marker_list[1].hour, marker_list[1].minute) - \
            pd.Timestamp(date.year, date.month, date.day, marker_list[0].hour, marker_list[0].minute)

        timesheet = timesheet.append({'start': marker_list[0], 'stop': marker_list[1], 'hours': hours}, ignore_index=True)

    start = timesheet.loc[0, 'start']
    stop = timesheet.loc[len(timesheet)-1, 'stop']

    def days_hours_minutes(td):
        return td.days, td.seconds//3600, (td.seconds//60) % 60

    total_worked = timesheet['hours'].sum()
    total_worked_decimal = str(days_hours_minutes(total_worked)[1]) + '{:.2}'.format(days_hours_minutes(total_worked)[2]/60)[1:]

    total_gross = stop - start
    total_rest = total_gross - total_worked

    if len(timesheet) == 1:
        start_rest = np.nan
        stop_rest = np.nan
    elif len(timesheet) == 2:
        start_rest = timesheet.stop[0]
        stop_rest = timesheet.stop[1]
    else:
        start_rest = start + (total_worked/2 - total_rest/2)
        stop_rest = start + (total_worked/2 + total_rest/2)

    # print(stop_rest-start_rest == total_rest)
    # print(stop-start-total_rest == total_worked)

    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

    print("******************************************")
    print(date.__str__() + " (" + days[date.weekday()] + ")")

    print("total_worked = " + total_worked.__str__())
    print("total_worked_decimal = " + total_worked_decimal)

    print("start = " + start.__str__())

    if len(timesheet) == 1:
        print('no rest...')
    else:
        print("start_rest = " + start_rest.__str__())
        print("stop_rest = " + stop_rest.__str__())

    print("stop = " + stop.__str__())

    my_tabulate(timesheet)

    return WorkDay(date=date, timesheet=timesheet, summary=Summary(start=start,
                                                                   stop=stop,
                                                                   total_worked=total_worked,
                                                                   total_worked_decimal=total_worked_decimal,
                                                                   total_gross=total_gross,
                                                                   total_rest=total_rest,
                                                                   start_rest=start_rest,
                                                                   stop_rest=stop_rest))


def get_work_episodes(data):
    tmp1 = data.split(' ')
    tmp2 = [None]*len(tmp1)

    for i in range(0, len(tmp1)):
        tmp2[i] = tmp1[i].split('-')

    return tmp2


## pay period 28/11/20 - 11/12/20

work_days = list()

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 18),
                episodes=[['14:31', '17:00']]))

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 19),
                episodes=[['11:02', '15:30'],
                          ['15:54', '17:52'],
                          ['20:47', '23:40']]))

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 20),
                episodes=[['9:30', '13:23'],
                          ['13:31', '16:58'],
                          ['17:25', '20:04']]))

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 22),
                episodes=[['13:53', '14:40'],
                          ['18:04', '19:22']]))

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 23),
                episodes=[['8:38', '14:01'],
                          ['17:54', '23:00']]))

work_days.append(enter_timesheet(date=datetime.date(2020, 12, 24),
                episodes=[['9:26', '9:42']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 4),
                episodes=[['11:49', '13:21'],
                          ['13:44', '15:15'],
                          ['15:32', '16:48'],
                          ['20:35', '22:03']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 5),
                episodes=[['9:47', '15:25'],
                          ['15:58', '17:38'],
                          ['18:14', '18:30'],
                          ['21:15', '22:49']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 6),
                episodes=[['7:31', '14:12'],
                         ['14:30', '16:48'],
                         ['17:24', '17:51'],
                         ['19:04', '21:28']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 7),
                episodes=[['9:56', '17:00'],
                         ['18:30', '19:19'],
                         ['20:20', '22:33']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 8),
                episodes=[['12:30', '16:59'],
                         ['18:16', '19:38']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 9),
                episodes=[['8:00', '9:39'],
                         ['10:59', '13:44'],
                         ['14:07', '15:05']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 11),
                episodes=[['13:38', '14:28'],
                         ['15:43', '18:16']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 12),
                episodes=[['11:30', '16:31'],
                         ['17:25', '19:55'],
                         ['21:05', '22:00']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 13),
                episodes=[['10:27', '14:27'],
                         ['15:32', '16:59'],
                         ['17:21', '17:28'],
                         ['18:58', '20:02']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 14),
                episodes=[['11:25', '14:03'],
                         ['15:48', '19:19'],
                         ['19:43', '20:02'],
                         ['20:08', '22:01'],
                         ['22:23', '23:16']]))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 15),
                episodes=get_work_episodes('1:04-3:25 9:45-10:23 11:46-14:27 15:28-18:32')))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 16),
                episodes=get_work_episodes('9:12-12:25 12:34-17:24 17:56-21:36')))

work_days.append(enter_timesheet(date=datetime.date(2021, 1, 18),
                episodes=get_work_episodes('7:22-12:56')))


##

work_summary = pd.DataFrame(({'date': pd.Series([], dtype='datetime64[ns]'),
                              'start': pd.Series([], dtype='datetime64[ns]'),
                              'stop': pd.Series([], dtype='datetime64[ns]'),
                              'total_worked': pd.Series([], dtype='timedelta64[ns]'),
                              'total_worked_decimal': pd.Series([], dtype='float'),
                              'total_gross': pd.Series([], dtype='timedelta64[ns]'),
                              'total_rest': pd.Series([], dtype='timedelta64[ns]'),
                              'start_rest': pd.Series([], dtype='datetime64[ns]'),
                              'stop_rest': pd.Series([], dtype='datetime64[ns]')}))

for work_day in work_days:

    work_summary = work_summary.append(
        pd.DataFrame({'date': pd.Series(work_day.date, dtype='datetime64[ns]'),
                      'start': pd.Series(work_day.summary.start, dtype='datetime64[ns]'),
                      'stop': pd.Series(work_day.summary.stop, dtype='datetime64[ns]'),
                      'total_worked': pd.Series(work_day.summary.total_worked, dtype='timedelta64[ns]'),
                      'total_worked_decimal': pd.Series(float(work_day.summary.total_worked_decimal), dtype='float'),
                      'total_gross': pd.Series(work_day.summary.total_gross, dtype='timedelta64[ns]'),
                      'total_rest': pd.Series(work_day.summary.total_rest, dtype='timedelta64[ns]'),
                      'start_rest': pd.Series(work_day.summary.start_rest, dtype='datetime64[ns]'),
                      'stop_rest': pd.Series(work_day.summary.stop_rest, dtype='datetime64[ns]')}), ignore_index=True)

##

work_summary2 = pd.DataFrame(({'date': pd.Series([], dtype='string'),
                              'start': pd.Series([], dtype='string'),
                              'stop': pd.Series([], dtype='string'),
                              'start_rest': pd.Series([], dtype='string'),
                              'stop_rest': pd.Series([], dtype='string'),
                              'total_worked': pd.Series([], dtype='float')}))

for i, row in work_summary.iterrows():

    start_rest_string = ""
    stop_rest_string = ""

    try:
        if row.start_rest == np.datetime64('NaT'):
            start_rest_string = np.nan
            stop_rest_string = np.nan
    except:
        start_rest_string = row.start_rest.time().__str__()[0:5]
        stop_rest_string = row.stop_rest.time().__str__()[0:5]

    work_summary2 = work_summary2.append(pd.DataFrame(({'date': pd.Series(row.date.date().__str__(), dtype='string'),
                                                        'start': pd.Series(row.start.time().__str__()[0:5], dtype='string'),
                                                        'stop': pd.Series(row.stop.time().__str__()[0:5], dtype='string'),
                                                        'total_worked': pd.Series(float("{:0.2f}".format(row.total_worked_decimal)), dtype='float'),
                                                        'start_rest': pd.Series(start_rest_string, dtype='string'),
                                                        'stop_rest': pd.Series(stop_rest_string, dtype='string')})), ignore_index=True)

my_tabulate(work_summary2)

print('Total Hours = ' + ("{:0.2f}".format(sum(work_summary2.total_worked))))




##

calendar_export = pd.DataFrame({'month': pd.Series([], dtype='int'),
                                'day': pd.Series([], dtype='int'),
                                'hours': pd.Series([], dtype='float')})

for i, row in work_summary.iterrows():
    calendar_export = calendar_export.append(pd.DataFrame({'month': pd.Series(row.date.month, dtype='int'),
                                                           'day': pd.Series(row.date.day, dtype='int'),
                                                           'hours': pd.Series(row.total_worked_decimal, dtype='float')}), ignore_index=True)






feather.write_feather(calendar_export, output_directory + "calendar_export.feather")




