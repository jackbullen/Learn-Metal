#include <iostream>
#include <cmath>
#include <vector>

class vec3
{
    public:
        double x, y, z;
        vec3(double x=0, double y=0, double z=0);
        vec3 operator+(const vec3 &other) const;
        vec3 operator-(const vec3 &other) const;
        vec3 operator*(double c) const;
        double norm() const;
        vec3 normalized() const;
};
