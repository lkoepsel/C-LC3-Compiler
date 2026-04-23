// max - find max value in array of values
// #include <stdio.h>

int main()
{
    int elements[] = { 3, 7, 2, 9, 4 };
    int max = elements[0];

    for (int i = 1; i<=4; i++)
    {
        if (elements[i] > max)
        {
            max = elements[i];
        }
    }
    // printf("%d", max);
}