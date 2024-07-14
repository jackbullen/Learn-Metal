#include <vector>
#include "Vector.h"

const double G = 6.67430e-11;

class Body
{
    private:
        double mass;
        vec3 x;
        vec3 v;
        vec3 F;
    
    public:
        Body(double mass, vec3 x, vec3 v);

        vec3 actingForces(const Body &other) const;
        void applyForce(vec3 force);
        void update(double dt);
        void resetForce();

        vec3 position() const;
        vec3 velocity() const;
        vec3 force() const;
        
        void setPosition(vec3 newx);
};

class System 
{
    private:
        std::vector<Body*> bodies;
    
    public:
        void add(Body *body);
        void applyForces();
        void update(double dt);
        void resetForces();
};