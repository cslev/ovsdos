# Policy Injection: A Cloud Dataplane DoS Attack - SIGCOMM'18 DEMO
Accompanying material for the SIGCOMM'18 Demo - Policy Injection: A Cloud Dataplane DoS Attack

### ABSTRACT
Enterprises continue to migrate their services into the cloud on a massive scale, but the increasing attack surface has
become natural target for malevolent actors. We show policy injection, a novel algorithmic complexity attack enabling
a tenant to add specially tailored ACLs into the data center fabric by exploiting the built-in security mechanisms
cloud management systems (CMS) offer to mount a denial-of-service attack. Our insight is that certain ACLs, when fed
with special covert packets by an attacker, may be very difficult to evaluate, leading to an exhaustion of cloud resources.
We show how a tenant can inject seemingly harmless ACLs into the cloud data plane to abuse an algorithmic deficiency
in the most popular cloud hypervisor switch, Open vSwitch, and reduce its effective peak performance by 80-90%, and, in
certain cases, denying network access.

### Video showcasing the demo
[![Link to Youtube showcase](https://img.youtube.com/vi/eRrk7mlFCas/0.jpg)](https://www.youtube.com/watch?v=eRrk7mlFCas)
