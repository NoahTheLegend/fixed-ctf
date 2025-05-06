int current_map = 0;

void LoadNextMapCustom()
{
    if (!isServer()) return;
    bool shuffle = sv_mapcycle_shuffle;

    ConfigFile cfg;
    if (!cfg.loadFile("mapcycle.cfg"))
    {
        print("Exiting and loading next map due to missing mapcycle.cfg");
        LoadNextMap();
        return;
    }
    else
    {
        string[] mapcycle;
        if (!cfg.readIntoArray_string(mapcycle, "mapcycle"))
        {
            print("Exiting and loading next map due to missing mapcycle array");
            LoadNextMap();
            return;
        }
        else
        {
            print("Loading next map normally out of "+mapcycle.length+" maps");
            int index = shuffle ? XORRandom(mapcycle.length) : current_map;
            LoadMap(mapcycle[index]);
            current_map = (index + 1) % mapcycle.length;
        }
    }
}