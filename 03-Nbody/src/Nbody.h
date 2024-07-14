#include <vector>
#include "Vector.h"

const float G = 1;

class Body
{
    private:
        float mass;
        vec3 x;
        vec3 v;
        vec3 F;
    
    public:
        Body(float mass, vec3 x, vec3 v);

        vec3 actingForces(const Body &other) const;
        void applyForce(vec3 force);
        void update(float dt);
        void resetForce();

        vec3 position() const;
        vec3 velocity() const;
        vec3 force() const;
        
        void setPosition(vec3 newx);
};

class System 
{
    public:
        std::vector<Body*> bodies;
        void add(Body *body);
        void applyForces();
        void update(float dt);
        void resetForces();
};