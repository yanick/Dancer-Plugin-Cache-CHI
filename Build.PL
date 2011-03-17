
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Carp' => '0',
    'Dancer::Test' => '0',
    'Module::Build' => '0.3601',
    'Scalar::Util' => '0',
    'Test::More' => '0.94',
    'perl' => '5.004'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Dancer plugin to cache response content (and anything else)',
  'dist_author' => [
    'Yanick Champoux <yanick@cpan.org>'
  ],
  'dist_name' => 'Dancer-Plugin-Cache',
  'dist_version' => '0.1.0',
  'license' => 'perl',
  'module_name' => 'Dancer::Plugin::Cache',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'CHI' => '0',
    'Dancer' => '0',
    'Dancer::Plugin' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
