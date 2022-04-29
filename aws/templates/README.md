This directory contains templates that utilize the modules in the parent directory.

There are two versions of template, v1 and v2, which use the corresponding v1 or v2 modules. The differences in v2 are as follows:

- Resource definitions are singular or list-based depending on the resource, e.g., an EKS cluster is singular while subnet definitions are list-based.
- Resource names are defined using the 'name' key inside a map rather than using a key => value name to enhance readability and consistency.