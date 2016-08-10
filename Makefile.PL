# -*- perl -*-

use strict;
use warnings;
use inc::Module::Install;

name           ('Bb-Collaborate-Ultra');
module_name    ('Bb::Collaborate::Ultra');
author         ('David Warring <david.warring@gmail.com>');
all_from       ('lib/Bb/Collaborate/Ultra.pm');
license	       ('perl');

requires(
    'Class::Accessor'              => 0,
    'Class::Data::Inheritable'     => 0,
    'Clone'                        => 0,
    'Crypt::JWT'                   => 0,
    'Date::Parse'                  => 0,
    'Data::Compare'                => 0,
    'JSON'                         => 0,
    'Mouse'                        => 0,
    'Mouse::Util::TypeConstraints' => 0,
    'parent'                       => 0,
    'REST::Client'                 => 0,
    'Scalar::Util'                 => 0,
    );

recommends(
    );

test_requires (
    );

repository("https://github.com/dwarring/p5-Bb-Ultra.git");

WriteAll;
