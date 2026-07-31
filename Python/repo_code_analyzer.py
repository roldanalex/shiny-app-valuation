#!/usr/bin/env python3
"""
Repository Code Analyzer and Cost Estimator
Replicates the behavior of repo_code_analyzer.R and shiny_cost_estimator.R

Usage:
  python3 Python/repo_code_analyzer.py analyze [path] [--avg-wage AVG] \
       [--complexity low|medium|high] [--team-exp N] [--reuse FLOAT] [--tools FLOAT]

  python3 Python/repo_code_analyzer.py estimate --lines N [--complexity low|medium|high] \
       [--team-exp N] [--reuse FLOAT] [--tools FLOAT]

Outputs an scc-style report to stdout and prints cost estimation details.
"""

import os
import sys
import argparse
import re
from collections import defaultdict
from math import pow


LANG_MAP = {
    '.r': 'R', '.js': 'JavaScript', '.jsx': 'JavaScript',
    '.ts': 'TypeScript', '.tsx': 'TypeScript', '.css': 'CSS',
    '.scss': 'Sass', '.sass': 'Sass', '.html': 'HTML', '.htm': 'HTML',
    '.md': 'Markdown', '.rmd': 'Markdown', '.qmd': 'Quarto',
    '.yml': 'YAML', '.yaml': 'YAML', '.json': 'JSON', '.xml': 'XML',
    '.svg': 'SVG', '.py': 'Python', '.tex': 'TeX', '.sh': 'Shell',
    '.txt': 'Plain Text', '.license': 'License', '.c': 'C', '.cpp': 'C++',
    '.h': 'C Header', '.java': 'Java', '.sql': 'SQL'
}

COMMENT_PATTERNS = {
    'R': [r'^\s*#'],
    'JavaScript': [r'^\s*//', r'^\s*/\*', r'^\s*\*'],
    'TypeScript': [r'^\s*//', r'^\s*/\*', r'^\s*\*'],
    'CSS': [r'^\s*/\*', r'^\s*\*'],
    'Sass': [r'^\s*//', r'^\s*/\*', r'^\s*\*'],
    'HTML': [r'^\s*<!--'],
    'Python': [r'^\s*#'],
    'Shell': [r'^\s*#'],
    'SQL': [r'^\s*--', r'^\s*/\*', r'^\s*\*'],
    'C': [r'^\s*//', r'^\s*/\*', r'^\s*\*'],
    'C++': [r'^\s*//', r'^\s*/\*', r'^\s*\*'],
    'Java': [r'^\s*//', r'^\s*/\*', r'^\s*\*']
}

EXCLUDE_PATTERNS = [
    '/.git/', '/.Rproj.user/', '/node_modules/', '/.venv/', '/venv/',
    '/__pycache__/', '/.DS_Store', '/.Rhistory', '/.RData', '/packrat/', '/renv/'
]

BINARY_EXTENSIONS = {
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.tiff', '.webp',
    '.woff', '.woff2', '.ttf', '.otf', '.eot',
    '.rds', '.rdata', '.rda', '.rdb', '.rdx',
    '.pyc', '.so', '.dylib', '.dll', '.o', '.class', '.jar',
    '.zip', '.tar', '.gz', '.bz2', '.xz', '.7z', '.rar',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.mp3', '.mp4', '.wav', '.avi', '.mov', '.ogg',
    '.sqlite', '.db', '.exe', '.bin', '.dat', '.lock',
}


def is_excluded(path):
    for p in EXCLUDE_PATTERNS:
        if p in path:
            return True
    return False


def is_binary_file(filepath):
    ext = os.path.splitext(filepath)[1].lower()
    if ext in BINARY_EXTENSIONS:
        return True
    try:
        with open(filepath, 'rb') as fh:
            chunk = fh.read(8192)
            if not chunk:
                return False
            return b'\x00' in chunk
    except Exception:
        return False


def analyze_repo(path='.'):
    results = []
    for root, dirs, files in os.walk(path):
        for f in files:
            full = os.path.join(root, f)
            rel = os.path.relpath(full, path)
            if is_excluded(full):
                continue
            if is_binary_file(full):
                continue
            try:
                ext = os.path.splitext(f)[1].lower()
                if ext == '' and re.search(r'LICENSE|LICENCE', f, re.I):
                    ext = '.license'
                language = LANG_MAP.get(ext, 'Other')

                with open(full, 'r', encoding='utf-8', errors='ignore') as fh:
                    lines = fh.readlines()
            except Exception:
                continue

            total_lines = len(lines)
            blank_lines = sum(1 for L in lines if re.match(r'^\s*$', L))

            # Single-pass OR to avoid double-counting comments
            patterns = COMMENT_PATTERNS.get(language, [])
            if patterns:
                compiled = [re.compile(pat) for pat in patterns]
                comment_lines = sum(
                    1 for L in lines
                    if any(prog.search(L) for prog in compiled)
                )
            else:
                comment_lines = 0

            code_lines = total_lines - blank_lines - comment_lines

            complexity_count = 0
            if language == 'R':
                complexity_count = sum(1 for L in lines if re.search(r'function\s*\(|for\s*\(|while\s*\(|if\s*\(', L))
            elif language in ('JavaScript', 'TypeScript'):
                complexity_count = sum(1 for L in lines if re.search(r'function\s+|=>|for\s*\(|while\s*\(|if\s*\(|class\s+', L))
            elif language == 'Python':
                complexity_count = sum(1 for L in lines if re.search(r'def\s+|class\s+|for\s+|while\s+|if\s+', L))

            file_size = os.path.getsize(full)

            results.append({
                'Language': language,
                'File': rel,
                'Lines': total_lines,
                'Blanks': blank_lines,
                'Comments': comment_lines,
                'Code': code_lines,
                'Complexity': complexity_count,
                'Bytes': file_size
            })

    if not results:
        print('No files found to analyze.')
        return None

    # Aggregate by language
    lang_summary = {}
    for r in results:
        L = r['Language']
        if L not in lang_summary:
            lang_summary[L] = {'Files': 0, 'Lines': 0, 'Blanks': 0, 'Comments': 0, 'Code': 0, 'Complexity': 0, 'Bytes': 0}
        lang_summary[L]['Files'] += 1
        lang_summary[L]['Lines'] += r['Lines']
        lang_summary[L]['Blanks'] += r['Blanks']
        lang_summary[L]['Comments'] += r['Comments']
        lang_summary[L]['Code'] += r['Code']
        lang_summary[L]['Complexity'] += r['Complexity']
        lang_summary[L]['Bytes'] += r['Bytes']

    # Sort by Code desc
    sorted_langs = sorted(lang_summary.items(), key=lambda kv: -kv[1]['Code'])

    # Totals
    totals = {'Files': 0, 'Lines': 0, 'Blanks': 0, 'Comments': 0, 'Code': 0, 'Complexity': 0, 'Bytes': 0}
    for L, stats in sorted_langs:
        for k in totals:
            totals[k] += stats[k]

    # Print report
    print('\n' + '-' * 79)
    print(f"{ 'Language':<20} { 'Files':>9} { 'Lines':>9} { 'Blanks':>9} { 'Comments':>9} { 'Code':>9} { 'Complexity':>10}")
    print('-' * 79)
    for L, s in sorted_langs:
        print(f"{L:<20} {s['Files']:9d} {s['Lines']:9d} {s['Blanks']:9d} {s['Comments']:9d} {s['Code']:9d} {s['Complexity']:10d}")
    print('-' * 79)
    print(f"{'Total':<20} {totals['Files']:9d} {totals['Lines']:9d} {totals['Blanks']:9d} {totals['Comments']:9d} {totals['Code']:9d} {totals['Complexity']:10d}")
    print('-' * 79)
    print(f"Processed {totals['Bytes']:,} bytes, {totals['Bytes'] / 1000000:.3f} megabytes (SI)")
    print('-' * 79 + '\n')

    return lang_summary, totals


def write_csv(basepath, lang_summary, totals, est):
    import csv
    csv_path = basepath + '.csv'
    with open(csv_path, 'w', newline='', encoding='utf-8') as fh:
        writer = csv.writer(fh)
        writer.writerow(['Language', 'Files', 'Lines', 'Blanks', 'Comments', 'Code', 'Complexity', 'Bytes'])
        for L, s in sorted(lang_summary.items(), key=lambda kv: -kv[1]['Code']):
            writer.writerow([L, s['Files'], s['Lines'], s['Blanks'], s['Comments'], s['Code'], s['Complexity'], s['Bytes']])
        writer.writerow([])
        writer.writerow(['Total', totals['Files'], totals['Lines'], totals['Blanks'], totals['Comments'], totals['Code'], totals['Complexity'], totals['Bytes']])
        writer.writerow([])
        writer.writerow(['Estimate', 'Value'])
        writer.writerow(['Estimated Cost (USD)', est.get('realistic_cost_usd', est.get('estimated_cost_usd'))])
        writer.writerow(['Estimated Schedule (months)', est.get('final_schedule_months', est.get('schedule_months'))])
        writer.writerow(['Estimated People', est.get('final_people', est.get('people_required'))])
        writer.writerow([])
        writer.writerow(['Realistic Project Breakdown', ''])
        writer.writerow(['Total effort (person-months)', est.get('original_effort')])
        writer.writerow(['Team size (people)', est.get('final_people')])
        writer.writerow(['Timeline (months)', est.get('final_schedule_months')])
        writer.writerow(['Average monthly cost (USD/month)', est.get('average_monthly_cost')])
        ci = est.get('confidence_interval', {})
        if ci:
            writer.writerow(['Confidence low', ci.get('low')])
            writer.writerow(['Confidence high', ci.get('high')])


def write_html(basepath, lang_summary, totals, est):
    html_path = basepath + '.html'
    with open(html_path, 'w', encoding='utf-8') as fh:
        fh.write('<html><head><meta charset="utf-8"><title>Repo Analysis</title></head><body>')
        fh.write('<h1>Repository Code Analysis</h1>')
        fh.write('<table border="1" cellpadding="6" cellspacing="0">')
        fh.write('<tr><th>Language</th><th>Files</th><th>Lines</th><th>Blanks</th><th>Comments</th><th>Code</th><th>Complexity</th><th>Bytes</th></tr>')
        for L, s in sorted(lang_summary.items(), key=lambda kv: -kv[1]['Code']):
            fh.write(f"<tr><td>{L}</td><td>{s['Files']}</td><td>{s['Lines']}</td><td>{s['Blanks']}</td><td>{s['Comments']}</td><td>{s['Code']}</td><td>{s['Complexity']}</td><td>{s['Bytes']}</td></tr>")
        fh.write('</table>')
        fh.write('<h2>Totals</h2>')
        fh.write(f"<p>Files: {totals['Files']} &nbsp; Lines: {totals['Lines']} &nbsp; Code: {totals['Code']}</p>")
        fh.write('<h2>Estimate</h2>')
        fh.write(f"<p>Estimated Cost (USD): ${est.get('realistic_cost_usd', est.get('estimated_cost_usd')):,}</p>")
        fh.write(f"<p>Estimated Schedule (months): {est.get('final_schedule_months', est.get('schedule_months'))}</p>")
        fh.write(f"<p>Estimated People: {est.get('final_people', est.get('people_required'))}</p>")
        ci = est.get('confidence_interval', {})
        if ci:
            fh.write(f"<p>Confidence Range: ${ci.get('low', 0):,} - ${ci.get('high', 0):,}</p>")
        fh.write('<h3>Realistic Project Breakdown</h3>')
        fh.write(f"<p>Total effort required: {est.get('original_effort')} person-months</p>")
        fh.write(f"<p>Team size: {est.get('final_people')} people</p>")
        fh.write(f"<p>Timeline: {est.get('final_schedule_months')} months</p>")
        fh.write(f"<p>Average monthly cost: ${est.get('average_monthly_cost'):,}/month</p>")
        if est.get('premium_multiplier') and est['premium_multiplier'] > 1.0:
            fh.write(f"<p>Cost premium: +{int((est.get('premium_multiplier')-1.0)*100)}% for aggressive timeline</p>")
        maint = est.get('maintenance')
        if maint:
            fh.write('<h3>Maintenance &amp; TCO</h3>')
            fh.write(f"<p>Annual Maintenance: ${maint['annual_maintenance']:,}</p>")
            fh.write(f"<p>Total Maintenance ({maint['maintenance_years']}yr): ${maint['total_maintenance']:,}</p>")
            fh.write(f"<p>Total Cost of Ownership: ${maint['tco']:,}</p>")
        fh.write('</body></html>')


def write_txt(basepath, lang_summary, totals, est):
    txt_path = basepath + '.txt'
    with open(txt_path, 'w', encoding='utf-8') as fh:
        fh.write('\n' + '-' * 79 + '\n')
        fh.write(f"{ 'Language':<20} { 'Files':>9} { 'Lines':>9} { 'Blanks':>9} { 'Comments':>9} { 'Code':>9} { 'Complexity':>10}\n")
        fh.write('-' * 79 + '\n')
        for L, s in sorted(lang_summary.items(), key=lambda kv: -kv[1]['Code']):
            fh.write(f"{L:<20} {s['Files']:9d} {s['Lines']:9d} {s['Blanks']:9d} {s['Comments']:9d} {s['Code']:9d} {s['Complexity']:10d}\n")
        fh.write('-' * 79 + '\n')
        fh.write(f"{'Total':<20} {totals['Files']:9d} {totals['Lines']:9d} {totals['Blanks']:9d} {totals['Comments']:9d} {totals['Code']:9d} {totals['Complexity']:10d}\n")
        fh.write('-' * 79 + '\n')
        fh.write(f"Processed {totals['Bytes']:,} bytes, {totals['Bytes'] / 1000000:.3f} megabytes (SI)\n")
        fh.write('-' * 79 + '\n\n')
        fh.write(f"Estimated Cost to Develop (realistic) ${est.get('realistic_cost_usd', est.get('estimated_cost_usd')):,}\n")
        fh.write(f"Estimated Schedule Effort (realistic) {est.get('final_schedule_months', est.get('schedule_months'))} months ({est.get('final_schedule_months', est.get('schedule_months')) / 12:.1f} years)\n")
        fh.write(f"Estimated People Required (realistic) {est.get('final_people', est.get('people_required'))}\n")
        ci = est.get('confidence_interval', {})
        if ci:
            fh.write(f"Confidence Range: ${ci.get('low', 0):,} - ${ci.get('high', 0):,}\n")
        fh.write('\nRealistic Project Breakdown:\n')
        fh.write(f"  Total effort required: {est.get('original_effort')} person-months\n")
        fh.write(f"  Team size: {est.get('final_people')} people\n")
        fh.write(f"  Timeline: {est.get('final_schedule_months')} months\n")
        if est.get('premium_multiplier') and est['premium_multiplier'] > 1.0:
            fh.write(f"  Cost premium: +{int((est.get('premium_multiplier')-1.0)*100)}% for aggressive timeline\n")
            fh.write(f"  Premium covers: Senior/expert engineers, overtime, consultants, accelerated tooling\n")
        fh.write(f"  Average monthly cost: ${est.get('average_monthly_cost'):,}/month\n")
        maint = est.get('maintenance')
        if maint:
            fh.write(f"\nMaintenance & TCO:\n")
            fh.write(f"  Annual Maintenance: ${maint['annual_maintenance']:,}\n")
            fh.write(f"  Total Maintenance ({maint['maintenance_years']}yr): ${maint['total_maintenance']:,}\n")
            fh.write(f"  Total Cost of Ownership: ${maint['tco']:,}\n")


def write_outputs(basepath, formats, lang_summary, totals, est):
    if 'csv' in formats:
        write_csv(basepath, lang_summary, totals, est)
    if 'html' in formats:
        write_html(basepath, lang_summary, totals, est)
    if 'txt' in formats:
        write_txt(basepath, lang_summary, totals, est)


def estimate_shiny_cost(code_lines, complexity='medium', team_experience=4, reuse_factor=1.0,
                        tool_support=1.0, language_mix=None, avg_wage=105000,
                        max_team_size=5, max_schedule_months=24,
                        rely=1.0, cplx=1.0, ruse=1.0, pcon=1.0, apex=1.0,
                        maintenance_rate=0.20, maintenance_years=0):
    # Input validation
    if not isinstance(code_lines, (int, float)) or code_lines < 0:
        raise ValueError("code_lines must be a non-negative number")
    if complexity not in ('low', 'medium', 'high'):
        raise ValueError("complexity must be 'low', 'medium', or 'high'")
    if not (1 <= team_experience <= 5):
        raise ValueError("team_experience must be between 1 and 5")
    if not (0.7 <= reuse_factor <= 1.3):
        raise ValueError("reuse_factor must be between 0.7 and 1.3")
    if not (0.8 <= tool_support <= 1.2):
        raise ValueError("tool_support must be between 0.8 and 1.2")
    if not (0.82 <= rely <= 1.26):
        raise ValueError("rely must be between 0.82 and 1.26")
    if not (0.73 <= cplx <= 1.74):
        raise ValueError("cplx must be between 0.73 and 1.74")
    if not (0.95 <= ruse <= 1.24):
        raise ValueError("ruse must be between 0.95 and 1.24")
    if not (0.81 <= pcon <= 1.29):
        raise ValueError("pcon must be between 0.81 and 1.29")
    if not (0.81 <= apex <= 1.22):
        raise ValueError("apex must be between 0.81 and 1.22")
    if not (0 <= maintenance_rate <= 1):
        raise ValueError("maintenance_rate must be between 0 and 1")
    if maintenance_years < 0:
        raise ValueError("maintenance_years must be non-negative")

    A = 2.50
    B = {'low': 1.02, 'medium': 1.10, 'high': 1.18}.get(complexity, 1.10)

    lang_productivity = {
        'R': 1.0, 'Python': 1.1, 'SQL': 1.3, 'JavaScript': 0.9,
        'CSS': 1.2, 'HTML': 1.3, 'Markdown': 1.5, 'Quarto': 1.5, 'YAML': 1.5, 'JSON': 1.5
    }

    if language_mix:
        weighted = 0.0
        for lang, lines in language_mix.items():
            prod = lang_productivity.get(lang, 1.0)
            weighted += (lines / prod)
        KLOC = weighted / 1000.0
    else:
        KLOC = code_lines / 1000.0

    EM_experience = 1.2 - 0.05 * team_experience
    EM_reuse = reuse_factor
    EM_tools = tool_support
    EM_modern = 0.85

    # COCOMO II cost drivers
    EM_rely = rely
    EM_cplx = cplx
    EM_ruse = ruse
    EM_pcon = pcon
    EM_apex = apex

    EM_total = (EM_experience * EM_reuse * EM_tools * EM_modern *
                EM_rely * EM_cplx * EM_ruse * EM_pcon * EM_apex)

    base_effort = A * pow(KLOC, B)
    effort = base_effort * EM_total

    C = 3.50
    D = 0.28 + 0.2 * (B - 1.01)
    schedule = C * pow(effort, D)
    people = effort / schedule if schedule > 0 else effort

    cost = round(effort * 12000)

    # Realistic constraints
    monthly_wage = avg_wage / 12.0
    original_people = people
    original_schedule = schedule
    original_effort = effort

    max_realistic_people = 8

    unconstrained_people = min(original_people, max_team_size)
    unconstrained_schedule = original_effort / unconstrained_people if unconstrained_people > 0 else original_effort

    final_people = min(unconstrained_people, max_realistic_people)
    natural_schedule = original_effort / final_people if final_people > 0 else original_effort
    final_schedule = min(natural_schedule, max_schedule_months)

    premium_multiplier = 1.0
    coordination_premium = 1.0

    if natural_schedule > max_schedule_months:
        compression_ratio = natural_schedule / final_schedule if final_schedule > 0 else natural_schedule
        if compression_ratio >= 4:
            premium_multiplier = 2.0
        elif compression_ratio >= 3:
            premium_multiplier = 1.7
        elif compression_ratio >= 2:
            premium_multiplier = 1.4
        else:
            premium_multiplier = 1.2
        realistic_cost = original_effort * monthly_wage * premium_multiplier
    else:
        if final_people >= 6:
            coordination_premium = 1.1
        realistic_cost = original_effort * monthly_wage * coordination_premium

    average_monthly_cost = round(realistic_cost / final_schedule) if final_schedule > 0 else 0

    # Confidence intervals
    confidence_interval = {
        'low': round(realistic_cost * 0.70),
        'high': round(realistic_cost * 1.30)
    }

    # Maintenance
    maintenance = None
    if maintenance_years > 0:
        annual_maintenance = realistic_cost * maintenance_rate
        yearly_costs = [round(annual_maintenance * (1.05 ** yr)) for yr in range(maintenance_years)]
        total_maintenance = sum(yearly_costs)
        tco = round(realistic_cost) + total_maintenance
        maintenance = {
            'annual_maintenance': round(annual_maintenance),
            'maintenance_years': maintenance_years,
            'maintenance_rate': maintenance_rate,
            'yearly_costs': yearly_costs,
            'total_maintenance': total_maintenance,
            'tco': tco
        }

    # Multiplier breakdown for waterfall chart
    multiplier_breakdown = {
        'base_effort': round(base_effort, 2),
        'EM_experience': EM_experience,
        'EM_reuse': EM_reuse,
        'EM_tools': EM_tools,
        'EM_modern': EM_modern,
        'EM_rely': EM_rely,
        'EM_cplx': EM_cplx,
        'EM_ruse': EM_ruse,
        'EM_pcon': EM_pcon,
        'EM_apex': EM_apex,
        'EM_total': EM_total
    }

    result = {
        'code_lines': code_lines,
        'effort_person_months': round(original_effort, 2),
        'schedule_months': round(schedule, 2),
        'people_required': round(people, 2),
        'estimated_cost_usd': cost,
        'realistic_cost_usd': round(realistic_cost),
        'final_people': round(final_people, 2),
        'final_schedule_months': round(final_schedule, 2),
        'premium_multiplier': premium_multiplier,
        'coordination_premium': coordination_premium,
        'average_monthly_cost': average_monthly_cost,
        'confidence_interval': confidence_interval,
        'maintenance': maintenance,
        'multiplier_breakdown': multiplier_breakdown,
        'original_effort': round(original_effort, 2),
        'original_people': round(original_people, 2),
        'original_schedule': round(original_schedule, 2),
        'natural_schedule': round(natural_schedule, 2),
        'max_realistic_people': max_realistic_people,
        'max_realistic_schedule': max_schedule_months,
        'params': {
            'complexity': complexity,
            'team_experience': team_experience,
            'reuse_factor': reuse_factor,
            'tool_support': tool_support,
            'avg_wage': avg_wage,
            'max_team_size': max_team_size,
            'max_schedule_months': max_schedule_months,
            'rely': rely, 'cplx': cplx, 'ruse': ruse, 'pcon': pcon, 'apex': apex,
            'maintenance_rate': maintenance_rate,
            'maintenance_years': maintenance_years
        }
    }

    return result


def print_shiny_cost_report(result):
    print('\n' + '-' * 79)
    print(f"{'Metric':<25} {'Value':>12}")
    print('-' * 79)
    print(f"{'Total Code Lines':<25} {result['code_lines']:12d}")
    print(f"{'Effort (person-months)':<25} {result['effort_person_months']:12.2f}")
    print(f"{'Schedule (months)':<25} {result['final_schedule_months']:12.2f}")
    print(f"{'People Required':<25} {result['final_people']:12.2f}")
    print(f"{'Estimated Cost (USD)':<25} ${result['realistic_cost_usd']:11,}")
    ci = result.get('confidence_interval', {})
    if ci:
        print(f"{'Confidence Range':<25} ${ci['low']:,} - ${ci['high']:,}")
    print('-' * 79)
    print('Parameters Used:')
    print(f"  Complexity:        {result['params']['complexity']}")
    print(f"  Team Experience:   {result['params']['team_experience']}")
    print(f"  Reuse Factor:      {result['params']['reuse_factor']:.2f}")
    print(f"  Tool Support:      {result['params']['tool_support']:.2f}")
    if result.get('premium_multiplier', 1.0) > 1.0:
        print(f"  Schedule Premium:  +{int((result['premium_multiplier']-1.0)*100)}%")
    if result.get('coordination_premium', 1.0) > 1.0:
        print(f"  Coordination:      +{int((result['coordination_premium']-1.0)*100)}%")
    maint = result.get('maintenance')
    if maint:
        print('-' * 79)
        print('Maintenance & TCO:')
        print(f"  Annual Maintenance:  ${maint['annual_maintenance']:,}")
        print(f"  Maintenance Years:   {maint['maintenance_years']}")
        print(f"  Total Maintenance:   ${maint['total_maintenance']:,}")
        print(f"  Total Cost (TCO):    ${maint['tco']:,}")
    print('-' * 79 + '\n')


def print_realistic_breakdown(est):
    print('\nRealistic Project Breakdown:')
    oe = est.get('original_effort') or est.get('effort_person_months')
    fp = est.get('final_people') or est.get('people_required')
    fs = est.get('final_schedule_months') or est.get('schedule_months')
    max_people = est.get('max_realistic_people')
    max_schedule = est.get('max_realistic_schedule')

    print(f"  Total effort required: {round(float(oe))} person-months")
    if max_people is not None:
        print(f"  Team size: {round(float(fp))} people (max allowed: {max_people})")
    else:
        print(f"  Team size: {round(float(fp))} people")
    if max_schedule is not None:
        print(f"  Timeline: {float(fs):.1f} months (max allowed: {max_schedule} months)")
    else:
        print(f"  Timeline: {float(fs):.1f} months")

    if est.get('premium_multiplier') and est['premium_multiplier'] > 1.0:
        print(f"  Cost premium: +{int((est['premium_multiplier']-1.0)*100)}% for aggressive timeline")
        print("  Premium covers: Senior/expert engineers, overtime, consultants, accelerated tooling")
    elif est.get('coordination_premium') and est['coordination_premium'] > 1.0:
        print(f"  Coordination overhead: +{int((est['coordination_premium']-1.0)*100)}% for team size")

    avg_month = est.get('average_monthly_cost')
    if avg_month is not None:
        print(f"  Average monthly cost: ${avg_month:,}/month")

    ci = est.get('confidence_interval', {})
    if ci:
        print(f"  Confidence range: ${ci.get('low', 0):,} - ${ci.get('high', 0):,}")


def main():
    parser = argparse.ArgumentParser(description='Repo analyzer and cost estimator')
    sub = parser.add_subparsers(dest='cmd')

    p_analyze = sub.add_parser('analyze')
    p_analyze.add_argument('path', nargs='?', default='.', help='Path to repository root')
    p_analyze.add_argument('--avg-wage', type=float, default=105000)
    p_analyze.add_argument('--complexity', choices=['low', 'medium', 'high'], default='medium')
    p_analyze.add_argument('--team-exp', type=int, default=4)
    p_analyze.add_argument('--reuse', type=float, default=1.0)
    p_analyze.add_argument('--tools', type=float, default=1.0)
    p_analyze.add_argument('--rely', type=float, default=1.0)
    p_analyze.add_argument('--cplx', type=float, default=1.0)
    p_analyze.add_argument('--ruse', type=float, default=1.0)
    p_analyze.add_argument('--pcon', type=float, default=1.0)
    p_analyze.add_argument('--apex', type=float, default=1.0)
    p_analyze.add_argument('--maintenance-rate', type=float, default=0.20)
    p_analyze.add_argument('--maintenance-years', type=int, default=0)
    p_analyze.add_argument('--out', help='Base path to write outputs (without extension)')
    p_analyze.add_argument('--formats', nargs='+', choices=['csv', 'html', 'txt'], default=['txt'])

    p_est = sub.add_parser('estimate')
    p_est.add_argument('--lines', type=int, required=True, help='Total code lines')
    p_est.add_argument('--complexity', choices=['low', 'medium', 'high'], default='medium')
    p_est.add_argument('--team-exp', type=int, default=4)
    p_est.add_argument('--reuse', type=float, default=1.0)
    p_est.add_argument('--tools', type=float, default=1.0)
    p_est.add_argument('--avg-wage', type=float, default=105000)
    p_est.add_argument('--rely', type=float, default=1.0)
    p_est.add_argument('--cplx', type=float, default=1.0)
    p_est.add_argument('--ruse', type=float, default=1.0)
    p_est.add_argument('--pcon', type=float, default=1.0)
    p_est.add_argument('--apex', type=float, default=1.0)
    p_est.add_argument('--maintenance-rate', type=float, default=0.20)
    p_est.add_argument('--maintenance-years', type=int, default=0)

    args = parser.parse_args()

    if args.cmd == 'analyze':
        result = analyze_repo(args.path)
        if result:
            lang_summary, totals = result
            language_mix = {L: stats['Code'] for L, stats in lang_summary.items()}
            total_code = sum(stats['Code'] for stats in lang_summary.values())
            est = estimate_shiny_cost(
                total_code, complexity=args.complexity, team_experience=args.team_exp,
                reuse_factor=args.reuse, tool_support=args.tools, language_mix=language_mix,
                avg_wage=args.avg_wage, rely=args.rely, cplx=args.cplx, ruse=args.ruse,
                pcon=args.pcon, apex=args.apex,
                maintenance_rate=args.maintenance_rate, maintenance_years=args.maintenance_years
            )
            print(f"Estimated Cost to Develop (realistic) ${est['realistic_cost_usd']:,}")
            print(f"Estimated Schedule Effort (realistic) {est['final_schedule_months']} months ({est['final_schedule_months'] / 12:.1f} years)")
            print(f"Estimated People Required (realistic) {est['final_people']}")
            if args.out:
                write_outputs(args.out, args.formats, lang_summary, totals, est)
            print_realistic_breakdown(est)
    elif args.cmd == 'estimate':
        res = estimate_shiny_cost(
            args.lines, complexity=args.complexity, team_experience=args.team_exp,
            reuse_factor=args.reuse, tool_support=args.tools, avg_wage=args.avg_wage,
            rely=args.rely, cplx=args.cplx, ruse=args.ruse, pcon=args.pcon, apex=args.apex,
            maintenance_rate=args.maintenance_rate, maintenance_years=args.maintenance_years
        )
        print_shiny_cost_report(res)
        print_realistic_breakdown(res)
    else:
        parser.print_help()


if __name__ == '__main__':
    main()
