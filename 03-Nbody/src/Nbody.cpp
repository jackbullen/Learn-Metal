#include "Nbody.h"

Body::Body(double mass, vec3 x, vec3 v)
    : mass(mass), x(x), v(v), F(vec3(0.0, 0.0, 0.0)) {}

vec3 Body::actingForces(const Body &other) const 
{
    vec3 r = other.position() - x;
    double distance = r.norm();
    double forceMagnitude = G * mass * other.mass / (distance * distance);
    return r.normalized() * forceMagnitude;
}

void Body::applyForce(vec3 force) {F = F + force;}

void Body::update(double dt)
{
    vec3 a = F * (1.0 / mass);
    v = v + a*dt;
    x = x + v*dt;
    F = vec3(); // reset force
}

void Body::resetForce() {F=vec3();}

vec3 Body::position() const {return x;}
vec3 Body::velocity() const {return v;}
vec3 Body::force() const {return F;}
void Body::setPosition(vec3 xn) {x = xn;}

void System::add(Body *body) 
{
    bodies.push_back(body);
}

void System::applyForces() 
{
    for (size_t i = 0; i < bodies.size(); i++)
    {
        for (size_t j = 0; j < bodies.size(); j++)
        {
            if (i != j)
            {
                vec3 force = bodies[i]->actingForces(*bodies[j]);
                bodies[i]->applyForce(force);
            }
        }
    }
}

void System::update(double dt)
{
    for (size_t i = 0; i < bodies.size(); i++)
    {
        bodies[i]->update(dt);
    }
}

void System::resetForces() 
{
    for (size_t i = 0; i < bodies.size(); i++)
    {
        bodies[i]->resetForce();
    }
}
