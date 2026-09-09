import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_spacing.dart';

class CRMSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const CRMSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius = 8.0,
  });

  @override
  State<CRMSkeleton> createState() => _CRMSkeletonState();
}

class _CRMSkeletonState extends State<CRMSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CRMMotion.skeleton,
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = CRMColors.skeletonBase;
    final highlight = CRMColors.skeletonHighlight;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, highlight, base],
              stops: [
                0.3 + (_animation.value - 2.0) * 0.15,
                0.5 + (_animation.value - 2.0) * 0.15,
                0.7 + (_animation.value - 2.0) * 0.15,
              ],
            ),
          ),
        );
      },
    );
  }
}

class CRMCardSkeleton extends StatelessWidget {
  const CRMCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.5),
          width: 0.5,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CRMSkeleton(width: 40, height: 40, borderRadius: 20),
          SizedBox(height: CRMSpacing.m),
          CRMSkeleton(width: 100, height: 16),
          SizedBox(height: CRMSpacing.xs),
          CRMSkeleton(width: 60, height: 24),
        ],
      ),
    );
  }
}

class CRMListSkeleton extends StatelessWidget {
  final int count;

  const CRMListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: CRMSpacing.m),
          child: Row(
            children: [
              CRMSkeleton(width: 48, height: 48, borderRadius: 24),
              SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CRMSkeleton(width: 120, height: 14),
                    SizedBox(height: CRMSpacing.xs),
                    CRMSkeleton(width: 200, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
