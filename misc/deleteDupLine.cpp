/*
 * deDup.cpp
 * Copyright (C) 2016  <@BLUEYI-PC>
 *
 * Distributed under terms of the MIT license.
 */

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char **argv)
{
    if (argc < 2) {
        std::cout << "No input file!" << std::endl;
        return 1;
    }
    std::string infile(argv[1]);
    std::string outfile = infile.substr(0, infile.find_last_of(".")) + "-nodup" + infile.substr(infile.find_last_of("."));
    std::ofstream ofs(outfile);
    std::ifstream ifs(infile);
    std::string line, nexline;
    int cont = 0;
    int total = 0;
    std::getline(ifs, line);
    while (std::getline(ifs, nexline)) {
        ++total;
        if (nexline == line)
            continue;
        ofs << line << std::endl;
        std::cout << line << std::endl;
        line = nexline;
        ++cont;
    }
    ofs << line << std::endl;
    std::cout << line << std::endl;
    std::cout << cont << " / " << total << std::endl;
    ofs.close();
    ifs.close();
    std::getchar();
    return 0;
}


