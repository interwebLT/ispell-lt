#!/usr/bin/env python
"""
Testai VDU KLC �odyno interfeisui.

$Id: test_donelaitis.py,v 1.1 2003/06/11 10:06:48 alga Exp $
"""

import unittest

class TestCorpusWord(unittest.TestCase):

    def test_parseTable(self):
        from donelaitis import parseTable

        table = """
        <html a=b><body>
        <table width=100%>
          <tr color="red">
            <td foo>aaa </td>
            <td> bbb  </td>
            <td foo> ccc </td>
          </tr>
          <tr>
            <td foo> ddd </td>
            <td> eee </td>
            <td foo> fff </td>
          </tr>
        </table>
        </body></html>
        """

        result = (('aaa', 'bbb', 'ccc'), ('ddd', 'eee', 'fff'))

        self.assertEquals(parseTable(table), result)
        self.assertEquals(parseTable("foo"), ())

    def test_fetch(self):
        from donelaitis import CorpusWord

        c = CorpusWord("mama", prefetch=False)
        c.html = """
        <html a=b><body>
        <table width=100%>
          <tr color="red">
            <td foo>aaa </td>
            <td> bbb  </td>
            <td foo> ccc </td>
          </tr>
          <tr>
            <td foo> ddd </td>
            <td> eee </td>
            <td foo> fff </td>
          </tr>
        </table>
        </body></html>
        """
        result = (('aaa', 'bbb', 'ccc'), ('ddd', 'eee', 'fff'))

        c.fetch()
        self.assertEqual(c.data, result)

    def test_totalMatches(self):
        from donelaitis import CorpusWord
        c = CorpusWord("mama", prefetch=False)
        c.data = (('gro�in�j', '12', '1234', '12345'),
                  ('publicistin�j', '13', '1234', '12345'),
                  ('viso', '', '1234', '12345'))
        self.assertEqual(c.totalMatches(), 25)


class TestIspell(unittest.TestCase):

    def test_entry(self):
        from ispell import splitEntry

        word, flags = splitEntry("namas/D\n")
        self.assertEqual(word, "namas")
        self.assertEqual(flags, "D")

        word, flags = splitEntry("vi��iukas/D\n")
        self.assertEqual(word, "vi��iukas")
        self.assertEqual(flags, "D")

        word, flags = splitEntry("geras/AQN\n")
        self.assertEqual(word, "geras")
        self.assertEqual(flags, "AQN")

        word, flags = splitEntry(" # �ia komentaras\n")
        self.assertEqual(word, "")
        self.assertEqual(flags, "")

        word, flags = splitEntry("ka�kada")
        self.assertEqual(word, "ka�kada")
        self.assertEqual(flags, "")

        word, flags = splitEntry("ka�kada # nekaitomas")
        self.assertEqual(word, "ka�kada")
        self.assertEqual(flags, "")

    def test_expand(self):
        from ispell import expand

        entry = "namas/D"

        result = ['namai', 'namais', 'namams', 'namas', 'name',
                  'namo', 'namu', 'namui', 'namuose', 'namus', 'nam�',
                  'nam�']

        self.assertEqual(expand(entry), result)


if __name__ == '__main__':
    unittest.main()
