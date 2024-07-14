#ifndef VECTOR_H
#define VECTOR_H

#include <iostream>
#include <cmath>
#include <vector>

class vec3
{
    public:
        float x, y, z;
        vec3(float x=0, float y=0, float z=0);
        vec3 operator+(const vec3 &other) const;
        vec3 operator-(const vec3 &other) const;
        vec3 operator*(float c) const;
        float norm() const;
        vec3 normalized() const;
};

#endif