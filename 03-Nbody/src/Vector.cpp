#include "Vector.h"

vec3::vec3(float x, float y, float z) : x(x), y(y), z(z) {}

vec3 vec3::operator+(const vec3 &other) const
{
    return vec3(x + other.x, y + other.y, z + other.z);
}

vec3 vec3::operator-(const vec3 &other) const
{
    return vec3(x - other.x, y - other.y, z - other.z);
}

vec3 vec3::operator*(float c) const
{
    return vec3(c*x, c*y, c*z);
}

float vec3::norm() const 
{
    return std::sqrt(x*x + y*y + z*z);
}

vec3 vec3::normalized() const 
{
    float n = norm();
    return vec3(x/n, y/n, z/n);
}