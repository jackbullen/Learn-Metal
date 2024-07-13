#include "Vector.h"

vec3::vec3(double x, double y, double z) : x(x), y(y), z(z) {}

vec3 vec3::operator+(const vec3 &other) const
{
    return vec3(x + other.x, y + other.y, z + other.z);
}

vec3 vec3::operator-(const vec3 &other) const
{
    return vec3(x - other.x, y - other.y, z - other.z);
}

vec3 vec3::operator*(double c) const
{
    return vec3(c*x, c*y, c*z);
}

double vec3::norm() const 
{
    return std::sqrt(x*x + y*y + z*z);
}

vec3 vec3::normalized() const 
{
    double n = norm();
    return vec3(x/n, y/n, z/n);
}