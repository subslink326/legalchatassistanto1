# {{ motion_type }}  
## {{ case_title }}

### I. Issues Presented
{% for issue in issues -%}
- {{ issue }}
{% endfor %}

### II. Statement of Facts
*(To be drafted)*

### III. Argument
{% for issue in issues -%}
A. {{ issue }}  
   1. Controlling law  
   2. Application to record facts  
{%- endfor %}

### IV. Conclusion
For the foregoing reasons, {{ party }} respectfully requests {{ prayer }}.

### Certificate of Compliance
*(Auto‑filled by Compliance Linter)*  
