void main ()
{
    // Simple Pointers
    int x = 1234;
    int y = 5678;
    int *p_x;
    int *p_y;
    int *p_z;

    x++;
    y--;

    p_x = &x;
    p_y = &y;
    p_z = 0;
    return;
}

