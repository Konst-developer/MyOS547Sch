#include <iostream>
#include <string>
#include <cstring>
#include <fstream>
#include <sstream>
#include <vector>
using namespace std;
struct FN
{
    uint32_t address;
    char funcName[28];
};
vector<FN> fncs;
FN fnc;
int main(int argc, char *argv[])
{
    string line;
    ifstream in(argv[1]);
    FILE *fl = fopen(argv[2], "wb");

    if (in.is_open())
    {
        getline(in, line);
        while (getline(in, line))
        {
            if (line.length())
            {
                string adrStr = line.substr(0, 8);
                stringstream ss;
                ss << hex << adrStr;
                ss >> fnc.address;

                string funcName = line.substr(11, 38);
                for (int i = 0; i < 28; i++)
                    fnc.funcName[i] = 0;
                strcpy(fnc.funcName, funcName.c_str());

                if (line[9] == 't')
                {
                    fncs.push_back(fnc);
                    // fwrite(&fnc, 32, 1, fl);
                    //  cout << fnc.funcName << " " << fnc.address << endl;
                }
            }
        }
    }

    fnc.address = 32 * fncs.size() + 32;
    for (int i = 0; i < 28; i++)
        fnc.funcName[i] = 0;
    fwrite(&fnc, 32, 1, fl);

    for (FN fn : fncs)
    {
        fwrite(&fn, 32, 1, fl);
    }
    in.close();
    fclose(fl);
}