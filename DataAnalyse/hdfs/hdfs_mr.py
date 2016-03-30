# -*- coding: utf-8 -*-
from mrjob.job import MRJob
import re
# python hdfs_mr.py -r hadoop --jobconf mapreduce.job.priority=VERY_HIGH -o hdfs://localhost:8020/output/httpflow hdfs://localhost:8020/user/root/website.com/20160204

class MRWordCounter(MRJob):
    def mapper(self, key, line):
        i = 0
        for flow in line.split():
            if i == 3:
                timerow = flow.split(":")
                hm = timerow[1] + ":" + timerow[2]
            if i == 9 and re.match(r"\d{1,}", flow):
                yield hm, int(flow)
            i += 1

    def reducer(self, key, occurrences):
        yield key, sum(occurrences)


class MRCounter(MRJob):
    def mapper(self, key, line):
        i = 0
        for httpcode in line.split():
            if i == 8 and re.match(r"\d{1,3}", httpcode):
                yield httpcode, 1
            i += 1

    def reducer(self, httpcode, occurrences):
         yield httpcode, sum(occurrences)

    def reducer_sorted(self, httpcode, occurrences):
        yield httpcode, sorted(occurrences)

    def steps(self):
        return [self.mr(mapper=self.mapper),
                self.mr(reducer=self.reducer)]


if __name__ == '__main__':
    MRWordCounter.run()