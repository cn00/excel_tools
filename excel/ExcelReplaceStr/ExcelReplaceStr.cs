﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NPOI.HSSF.UserModel;
using NPOI.XSSF.UserModel;
using NPOI.SS.UserModel;
using System.IO;
using System.Text.RegularExpressions;
using NPOI;

namespace ExcelRpelaceStr
{
    class ExcelReplaceStr
    {
        static void Main(string[] args)
        {
            string inputdir = ".";
            string oldStr = null;
            string newStr = null;
            if(args.Length == 3)
            {
                inputdir = args[0];
                oldStr = args[1];
                newStr = args[2];
                goto go;
            }
            begin:
            Console.WriteLine("usage: ExcelRpelaceStr oldStr newStr\n或按下面提示操作");
            Console.WriteLine("输入待替换 Excel 根路径, 默认值: " + inputdir);
            Console.Write("输入或拖入: ");
            var tmp = Console.ReadLine();
            if(!string.IsNullOrWhiteSpace(tmp) && Directory.Exists(tmp))
                inputdir = tmp;
            else
            {
                goto begin;
            }

            inputdir = inputdir.upath();
            Console.WriteLine("待替换 Excel 根路径为: " + inputdir);

            input_old_str:
            Console.Write("输入原始字符串: ");
            oldStr = Console.ReadLine();
            if(string.IsNullOrEmpty(oldStr))
                goto input_old_str;

            input_new_str:
            Console.Write("输入新字符串: ");
            newStr = Console.ReadLine();
            if(string.IsNullOrEmpty(newStr))
                goto input_new_str;

            Console.WriteLine("将替换全部 [{0}] 为 [{1}]", oldStr, newStr);
            Console.Write("按 Enter 确认: ");
            Console.ReadLine();

            go:
            foreach(var f in Directory.GetFiles(inputdir, "*.*", SearchOption.AllDirectories)
                .Where(f => f.EndsWith(".xls") || f.EndsWith(".xlsx")))
            {
                var fin = f.upath();
                Replace(fin, oldStr, newStr);
                //Console.WriteLine(fin);
            }// foreach

            Console.Write("\n搜索了 {0} 个文件, 替换了 {1} 个匹配\n", FileColCount, MatchColCount);
            //Console.WriteLine("按 Enter 退出");
            var os = Environment.OSVersion.ToString();
            Console.WriteLine(os);
            if (!os.Contains("Unix"))
            {
                Console.WriteLine("按 Enter 退出");
                Console.ReadLine();
            }
        }//end main

        const string space = "                  ";
        static int FileColCount = 0;
        static int MatchColCount = 0;
        public static void Replace(string inExcel, string oldStr, string newStr)
        {
            var inStream = new FileStream(inExcel, FileMode.Open);

            IWorkbook inbook = null;
            if(inExcel.EndsWith(".xls"))
            {
                inbook = new HSSFWorkbook(inStream);
            }
            else if(inExcel.EndsWith(".xlsx"))
            {
                inbook = new XSSFWorkbook(inStream);
            }
            inStream.Close();

            ++FileColCount;
            //Console.WriteLine(fColCount + " <<< " + inExcel);
            Console.Write(FileColCount + " <<< " + inExcel + space + "\r");

            int count = 0;
            string outStr = FileColCount + ": " + inExcel + space;
            foreach(var sheet in inbook.AllSheets())
            {
                for(int i = 1; i <= sheet.LastRowNum; ++i)
                {
                    var row = sheet.Row(i);
                    for(int j = 0; j < row.LastCellNum; ++j)
                    {
                        var c = row.Cell(j);
                        var v = c.SValue();
                        if(v.Contains(oldStr))
                        {
                            ++MatchColCount;
                            ++count;
                            var ns = v.Replace(oldStr, newStr);
                            outStr += string.Format("\n\t{0}[{1}, {2}]: [{3}]", sheet.SheetName, i, j, ns.oneline());
                            c.SetCellValue(ns);
                        }
                    }
                }
            }

            if(count > 0)
            {
                Console.Write(outStr + "                  \n");
                inStream = new FileStream(inExcel, FileMode.Create);
                inbook.Write(inStream);
                inStream.Close();
            }
        }

    }
}
